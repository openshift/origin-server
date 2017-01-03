var path          = require('path');
var fs            = require('fs');
var util          = require('util');
var events        = require('events');
var http          = require('http');
var https         = require('https');
var WebSocket     = require('ws');
var child_process = require('child_process');

var ProxyRoutes   = require('./ProxyRoutes.js');
var constants     = require('../utils/constants.js');
var httputils     = require('../utils/http-utils.js');
var statuscodes   = require('../utils/status-codes.js');
var errorpages    = require('../utils/error-pages.js');
var Logger        = require('../logger/Logger.js');

/*!  {{{  section:  'Private-Variables'                                  */

/*  Default timeouts.  */
var DEFAULT_IO_TIMEOUT         = 300;   /*  5 minutes (300 seconds).  */
var DEFAULT_KEEP_ALIVE_TIMEOUT = 60;    /*  1 minute (60 seconds).    */
var DEFAULT_WEBSOCKETS_TIMEOUT = 3600;  /*  1 hour (3600 seconds).    */

/*!
 *  }}}  //  End of section  Private-Variables.
 *  ---------------------------------------------------------------------
 */


/*!  {{{  section: 'Internal-Functions'                                  */

/**
 *  Loads the proxy server config file (JSON format).
 *
 *  Examples:
 *    _load_config('/etc/openshift/web-proxy.json');
 *
 *  @param   {String}  config file (JSON format).
 *  @return  {Dict}    loaded configuration.
 *  @api     private
 */
function _load_config(f) {
  try {
    return require(f);

  } catch(err) {
    Logger.error("Failed to load proxy config file '" + f + ' - ' + err);
    throw new Error("Failed to load proxy config file '" + f + ' - ' + err);
  }

  return { };

}  /*  End of function  _load_config.  */


/**
 *  Set the response headers on the proxied response.
 *
 *  Examples:
 *    var preq = http.request(proxy_req, function(pres) {
 *      _setProxyResponseHeaders(pres, 'app1-ramr.rhcloud.com', 60);
 *    });
 *
 *  @param  {http.ClientResponse}  Response from the proxied request.
 *  @param  {String}               Virtual host name
 *  @param  {Integer}              Connection Keep-Alive timeout
 *  @api    private
 */
function _setProxyResponseHeaders(proxy_res, res, vhost, keep_alive_timeout) {
  /* Copy the headers to original res */
  for (var key in proxy_res.headers) {
    if (key != 'connection') {
      res.setHeader(key, proxy_res.headers[key]);
    }
  }

  var about_me = constants.NODE_PROXY_WEB_PROXY_NAME + '/' +
                 constants.NODE_PROXY_PRODUCT_VER;
  var zroute   = '1.1 ' + vhost + ' (' + about_me + ')';

  /*  Set the Via: header to indicate it went via us.  */
  res.setHeader('Via', zroute);

  /*  Set the Keep-Alive timeout if Connection is being kept alive.  */
  var conn_header = proxy_res.headers['Connection']  ||  '';
  if ('keep-alive' === conn_header.toLowerCase() ) {
    var ka = utils.format('timeout=%d, max=%d', keep_alive_timeout,
                          keep_alive_timeout + DEFAULT_KEEP_ALIVE_TIMEOUT);
    res.setHeader('Keep-Alive', ka);
  }
}  /*  End of function  _setProxyResponseHeaders.  */


/**
 *  Set the request headers on the proxied request.
 *
 *  Examples:
 *    var proxy_req = { host: ep_host, port: ep_port,
 *                      method: req.method, path: request_uri,
 *                      headers: req.headers
 *                    };
 *    _setProxyRequestHeaders(proxy_req, req);
 *
 *  @param  {http.ClientRequest}  The request we send to the endpoint.
 *  @param  {http.ServerRequest}  The request we received.
 *  @api    private
 */
function _setProxyRequestHeaders(proxy_req, orig_req) {
  /*  Set X-Forwarded-For HTTP extension header.  */
  var xff = orig_req.connection.remoteAddress  ||
            orig_req.socket.remoteAddress;
  httputils.addHeader(proxy_req.headers, 'X-Forwarded-For', xff);

  /*  Set X-Client-IP HTTP extension header.      */
  httputils.addHeader(proxy_req.headers, 'X-Client-IP', xff);

  /*  Set X-Forwarded-Proto HTTP extension header.  */
  var proto = orig_req.connection.encrypted? 'https' : 'http';
  httputils.addHeader(proxy_req.headers, 'X-Forwarded-Proto', proto);

  /* Set X-Forwarded-Host HTTP extension header. */
  var hostport = orig_req.headers.host;
  httputils.addHeader(proxy_req.headers, 'X-Forwarded-Host', hostport.split(':')[0]);
  httputils.addHeader(proxy_req.headers, 'X-Forwarded-Port', hostport.split(':')[1]);

  if (orig_req.httpVersion < 1.1) {
     httputils.addHeader(proxy_req.headers, 'Connection', 'close');
  }

}  /*  End of function  _setProxyRequestHeaders.  */


/**
 *  Handler to process the HTTP[S] request we received and route to
 *  the appropriate endpoint and proxy traffic to-and-fro from the
 *  the endpoint.
 *
 *  Examples:
 *    var ProxyServer  = require('./proxy/ProxyServer.js');
 *    var cfgfile      = '/etc/openshift/web-proxy.json';
 *    var proxy_server = new ProxyServer.ProxyServer(cfgfile);
 *    proxy_server.initServer();
 *
 *    var zserver = httputils.createProtocolServer('http');
 *    zserver.on('request', function(req, res) {
 *      _requestHandler(proxy_server, req, res);
 *    });
 *
 *  @param  {ProxyServer}         Proxy server instance.
 *  @param  {http.ClientRequest}  The request we send to the endpoint.
 *  @param  {http.ServerRequest}  The request we received.
 *  @api    private
 */
function _requestHandler(proxy_server, req, res) {
  /*  Get the request/socket io timeout.  */
  var io_timeout = DEFAULT_IO_TIMEOUT;   /*  300 seconds.  */
  if (proxy_server.config.timeouts  &&  proxy_server.config.timeouts.io) {
    io_timeout = proxy_server.config.timeouts.io;
  }

  /*  Set timeout on the incoming request/socket.  */
  req.socket.setTimeout(io_timeout * 1000);  /*  Timeout is in ms.  */

  /*  Get the keepalive timeout.  */
  var keep_alive_timeout = DEFAULT_KEEP_ALIVE_TIMEOUT;  /*  60 seconds.  */
  if (proxy_server.config.timeouts  &&
      proxy_server.config.timeouts['keep-alive']) {
    keep_alive_timeout = proxy_server.config.timeouts['keep-alive'];
  }


  var reqhost = '';
  var reqport = 8000;

  /*  Get the host, the request was sent to.  */
  if (req.headers  &&  req.headers.host) {
    reqhost = req.headers.host.split(':')[0];
  }

  var idled_container = proxy_server.getIdle(reqhost)
  if (idled_container && 0 !== idled_container.length) {
    var command = 'curl -s -k -L -w %{http_code} -o /dev/null http://' + reqhost
    Logger.debug('Unidle command for http: ' + command);

    child_process.exec(command, function (error, stdout, stderr) {
      if (null != stderr) {
        Logger.error('curl stderr: ' + stderr);
      }

      if (null != error) {
        Logger.error('curl error: ' + error);
      }

      if ('200' == stdout) {
        proxy_server.unIdle(reqhost);
        finish_request(reqhost, reqport, proxy_server, req, res, io_timeout, keep_alive_timeout);
      }
    });
  }
  else {
    finish_request (reqhost, reqport, proxy_server, req, res, io_timeout, keep_alive_timeout);
  }
};  /*  End of function  requestHandler.  */

function finish_request (reqhost, reqport, proxy_server, req, res, io_timeout, keep_alive_timeout) {
  var surrogate = new RequestSurrogate(req, res);

  /*  Emit Surrogate Request and start events.  */
  proxy_server.emit('surrogate.request', surrogate);
  surrogate.emit('start');

  proxy_server.debug()  &&  Logger.debug('Handling HTTP[S] request to ' + reqhost);

  /*  Get the request URI.  */
  var request_uri = req.url ? req.url : '/';


  /*  Get the routes to the destination (try with request URI first).  */
  var routes = proxy_server.getRoute(reqhost, request_uri);

  /*  No route, no milk [, no cookies] ... return a temporary redirect.  */
  if (!routes  ||  (routes.length < 1)  ||  (routes[0].length < 1) ) {
    /*  Send a temporary redirect to the 404 redirect location.  */
    res.statusCode = statuscodes.HTTP_FOUND;
    res.setHeader('Location', proxy_server.config.routes.redirect404);
    res.end('');

    /*  Routing error.  */
    surrogate.emit('error', 'route.error');
    return;
  }

  /*  Get the endpoint we need to send this request to.  */
  var ep = routes[0].split(':');
  var matched_path = ep[2];
  var ep_host = ep[0];
  var parts = ep[1].split('/');
  var ep_port = parts[0] || 8080;
  var req_path = request_uri;
  var ep_path = undefined;
  if (parts.length > 1) {
    ep_path = '/' + parts.slice(1).join('/');
    req_path = req_path.replace(matched_path, ep_path);
  }

  proxy_server.debug()  &&  Logger.debug('Sending a proxy request to %s %s', ep_host, req_path);

  /*  Create a proxy request we need to send & set appropriate headers.  */
  var proxy_req = { host: ep_host, port: ep_port,
    method: req.method, path: req_path,
    headers: req.headers
  };
  _setProxyRequestHeaders(proxy_req, req);

  var preq = http.request(proxy_req, function(pres) {
    /*  Set surrogate's backend information.  */
    surrogate.setBackendInfo(preq, pres);

    /*  Response started event.  */
    surrogate.emit('begin-response');

    /*  Handle the proxy response error/end/data events.  */
    pres.addListener('error', function() {
      /*  Finish the response to the originating request and emit event.  */
      res.end();
      surrogate.emit('error', 'proxy.response.error');
    });

    pres.addListener('end', function() {
      /*  Finish the response to the originating request and emit event.  */
      res.end();
      surrogate.emit('end');
    });

    pres.addListener('data', function(chunk) {
      /*  Emit event and proxy response to the request originator.  */
      surrogate.emit('outbound.data', chunk);
      res.write(chunk);
    });

    /*  Set the appropriate headers on the reponse & send the headers.  */
    _setProxyResponseHeaders(pres, res, reqhost, keep_alive_timeout);
    res.writeHead(pres.statusCode);
  });

  /*  Handle the outgoing request socket event and set a timeout.  */
  preq.on('socket', function(socket) {
    socket.setTimeout(io_timeout * 1000);  /*  Timeout is in ms.  */
    socket.on('timeout', function() {
      /*  Abort the request and emit timeout event.  */
      preq.abort();
      surrogate.emit('error', 'socket.timeout');
    });
  });


  /*  Handle the incoming request error/end/data events.  */
  req.addListener('error', function() {
    /*  Finish the proxied request, return a 503.  */
    preq.abort();
    res.statusCode = statuscodes.HTTP_SERVICE_UNAVAILABLE;
    res.write(errorpages.service_unavailable_page(reqhost, reqport) );
    res.end();

    /*  Emit error event.  */
    surrogate.emit('error', 'request.error');
  });

  req.addListener('end', function() {
    /*  Finish outgoing request to the backend content server & emit event.  */
    preq.end();
    surrogate.emit('end-request');
  });

  req.addListener('data', function(chunk) {
    /*  Emit event and proxy data to the backend content server.  */
    surrogate.emit('inbound.data', chunk);
    preq.write(chunk);
  });


  /*  Handle the outgoing request error event.  */
  preq.addListener('error', function(error) {
    Logger.error('io_timeout: ' + io_timeout)
    Logger.error('Error listener on proxied request: ' + error.stack)

    /*  Finish the incoming request, return a 503 and emit event.  */
    res.statusCode = statuscodes.HTTP_SERVICE_UNAVAILABLE;
    res.write(errorpages.service_unavailable_page(reqhost, reqport) );
    res.end('');
    surrogate.emit('error', 'proxy.request.error');
  });

  res.addListener('close', function() {
    Logger.debug("Client closed the connection");
    preq.abort();
  });
}

/**
 *  Handler to process websockets traffic we receive and route to the
 *  appropriate websocket endpoint and proxy traffic to-and-fro from the
 *  the websocket endpoint.
 *
 *  Examples:
 *    var ProxyServer  = require('./proxy/ProxyServer.js');
 *    var cfgfile      = '/etc/openshift/web-proxy.json';
 *    var proxy_server = new ProxyServer.ProxyServer(cfgfile);
 *    proxy_server.initServer();
 *
 *    var zserver = httputils.createProtocolServer('http');
 *    var wssrvr  = new WebSocket.Server({server: zserver});
 *    wssrvr.on('connection', function(ws) {
 *      _websocketHandler(self, ws);
 *    });
 *
 *  @param  {ProxyServer}  Proxy server instance.
 *  @param  {WebSocket}    The incoming websocket (what we received).
 *  @api    private
 */
function _websocketHandler(proxy_server, ws) {

  /*  Get websockets timeout.  */
  var websockets_timeout = DEFAULT_WEBSOCKETS_TIMEOUT;  /*  3600 secs.  */
  if (proxy_server.config.timeouts  &&
      proxy_server.config.timeouts.websockets) {
    websockets_timeout = proxy_server.config.timeouts.websockets;
  }

  /*  Timeout is set in milliseconds, so convert from seconds.  */
  ws._socket.setTimeout(websockets_timeout * 1000);

  /*  Get the original/upgraded HTTP request.  */
  var upgrade_req = ws.upgradeReq  ||  { };
  var upg_reqhost = '';

  /*  Get the host, the original/upgraded HTTP request was sent to.  */
  if (upgrade_req.headers  &&  upgrade_req.headers.host) {
    upg_reqhost = upgrade_req.headers.host.split(':')[0];
  }

  var idled_container = proxy_server.getIdle(upg_reqhost)
  if (idled_container && 0 !== idled_container.length) {
    var command = 'curl -s -k -L -w %{http_code} -o /dev/null http://' + upg_reqhost
    Logger.debug('Unidle command for ws: ' + command);

    child_process.exec(command, function (error, stdout, stderr) {
      if (null != stderr) {
        Logger.error('curl stderr: ' + stderr);
      }

      if (null != error) {
        Logger.error('curl error: ' + error);
      }

      if ('200' == stdout) {
        proxy_server.unIdle(upg_reqhost);
        finish_websocket (upg_reqhost, proxy_server, ws);
      }
    });
  }
  else {
    finish_websocket (upg_reqhost, proxy_server, ws);
  }

};  /*  End of function  websocketHandler.  */

function finish_websocket(upg_reqhost, proxy_server, ws) {
  var surrogate = new WebSocketSurrogate(ws);

  /*  Emit Surrogate Websocket and start events.  */
  proxy_server.emit('surrogate.websocket', surrogate);
  surrogate.emit('start');

  /*  Get the original/upgraded HTTP request.  */
  var upgrade_req = ws.upgradeReq  ||  { };
  var upg_reqhost = '';

  /*  Get the host, the original/upgraded HTTP request was sent to.  */
  if (upgrade_req.headers  &&  upgrade_req.headers.host) {
    upg_reqhost = upgrade_req.headers.host.split(':')[0];
  }

  /*  Get the original request URI.  */
  var upg_requri = upgrade_req.url ? upgrade_req.url : '/';

  /*  Get the routes to the destination (try with request URI first).  */
  var routes = proxy_server.getRoute(upg_reqhost, upg_requri);
  /*
  if (routes.length < 1) {
    /*  No specific route, try the more general route.
    routes = proxy_server.getRoute(upg_reqhost);
  }
  */

  /*  No route, no milk [, no cookies] ... return unexpected condition.  */
  if (!routes  ||  (routes.length < 1)  ||  (routes[0].length < 1) ) {
    /*  Send an unexpected condition error - no route.  */
    ws.close(statuscodes.WS_UNEXPECTED_CONDITION,
             proxy_server.config.routes.redirect_missing);

    /*  Emit websocket routing error event.  */
    surrogate.emit('error', 'websocket.route.error');

    return;
  }


  /* Take out the matched endpoint from the result */
  var ws_endpoint = routes[0].split(":").slice(0, 2).join(":");
  var req_path = routes[0].split(":")[1];

  proxy_server.debug()  &&  Logger.debug('Sending a websocket request to %s',
                                         util.inspect(ws_endpoint));

  var zheaders = { 'headers': {}};

  zheaders.headers['user-agent'] = upgrade_req.headers['user-agent'];

  /*  Set X-Forwarded-For HTTP extension header.  */
  var xff = upgrade_req.connection.remoteAddress  ||
            upgrade_req.socket.remoteAddress;
  zheaders.headers['X-Forwarded-For'] = xff;

  /*  Set X-Client-IP HTTP extension header.      */
  zheaders.headers['X-Client-IP'] = xff;

  proxy_server.debug()  &&  Logger.debug(JSON.stringify(upgrade_req.headers));

  /* Pass down the cookie, if any */
  if (upgrade_req.headers.cookie) {
    zheaders.headers.Cookie = upgrade_req.headers.cookie;
  }

  if (upgrade_req.headers["sec-websocket-protocol"]) {
    zheaders.headers["Sec-Websocket-Protocol"] = upgrade_req.headers["sec-websocket-protocol"];
  }
  if (upgrade_req.headers["origin"]) {
    zheaders.headers["Origin"] = upgrade_req.headers["origin"];
  }
  
  if (upgrade_req.headers["authorization"]) {
    zheaders.headers["Authorization"] = upgrade_req.headers["authorization"];
  }

  /*  Create a proxy websocket request we need to send.  */
  var proxy_ws = new WebSocket('ws://' + ws_endpoint + upg_requri, zheaders);

  /*  Set surrogate's backend information.  */
  surrogate.setBackendInfo(proxy_ws);

  /*  Handle the proxy websocket error/open/close/message events.  */
  proxy_ws.on('error', function(err) {
    /*  Finish the websocket request w/ an unexpected condition status.  */
    ws.close(statuscodes.WS_UNEXPECTED_CONDITION);
    proxy_ws.terminate();

    /*  Emit proxy websocket error event.  */
    surrogate.emit('error', 'proxy.websocket.error');
  });

  proxy_ws.on('open', function() {
    /*  Websocket proxy started event.  */
    surrogate.emit('start-proxy-websocket');

    for (var i = 0; i < surrogate.buffer.length; i++) {
      var data = surrogate.buffer[i].data;
      var flags = surrogate.buffer[i].flags;
      Logger.error("Replaying buffer data: " + data);
        proxy_ws.send(data, flags);
      }
    surrogate.buffer = [];
  });

  proxy_ws.on('close', function() {
    /*  Finish the websocket request normally and emit end event.  */
    ws.close(statuscodes.WS_NORMAL_CLOSURE);
    surrogate.emit('end-proxy-websocket');
  });

  proxy_ws.on('message', function(data, flags) {
    // do not crash the whole proxy, when the connection is not open
    // https://bugzilla.redhat.com/show_bug.cgi?id=1042938
    try {
      /*  Emit websocket outbound data event.  */
      surrogate.emit('outbound.data', data, flags);

      /*  Proxy message back to the websocket request originator.  */
      ws.send(data, flags);
    }
    catch(err) {
      Logger.error("failed to send message: " + err);
      surrogate.emit('error', 'websocket.error');
    };

  });

  /*  Handle the incoming websocket error/close/message events.  */
  ws.on('error', function() {
    /*  Finish the websocket request w/ an unexpected condition status.  */
    proxy_ws.close(errorpages.WS_UNEXPECTED_CONDITION);
    ws.terminate();

    /*  Emit websocket error event.  */
    surrogate.emit('error', 'websocket.error');
  });

  ws.on('close', function() {
    /*  Finish the websocket request normally and emit normal closure event.  */
    proxy_ws.close(errorpages.WS_NORMAL_CLOSURE);
    surrogate.emit('end');
  });

  ws.on('message', function(data, flags) {
    /*  Emit inbound data event.  */
    surrogate.emit('inbound.data', data, flags);
    if (proxy_ws.readyState == WebSocket.OPEN) {
      /*  Proxy data to outgoing websocket to the backend content server.  */
      proxy_ws.send(data, flags);
    } else {
      if (surrogate.buffer.length < 5) {
        surrogate.buffer.push({data: data, flags: flags})
      }
    }
  });

  /* Clear the buffer */
  setTimeout(function() {
      surrogate.buffer = [];
  }, 3000);

};  /*  End of function  websocketHandler.  */

/**
 *  Asynchronously find the route files and invoke the specify callback to
 *  load the route files.
 *
 *  Examples:
 *    var cfgfile      = '/etc/openshift/web-proxy.json'
 *    var proxy_server = new ProxyServer(cfgfile);
 *    var routes_cfg   = proxy_server.config.routes;
 *    _asyncLoadRouteFiles(routes_cfg, function(route_files) {
 *      route_files.forEach(function(f) { proxy_server.routes.load(f); });
 *    });
 *
 *  @param  {Dict}      The routes config dictionary - indicates how to get
 *                      the list of route files.
 *  @param  {Function}  The callback to invoke.
 *  @api    private
 */
function _asyncLoadRouteFiles(routes, callback) {
  /*  Need to get the routes via a command, exec it and pass callback.  */
  if (routes  &&  routes.cmd) {
    return child_process.exec(routes.cmd, { maxBuffer: 400 * 8192 }, function(err, stdout, stderr) {
      return callback(stdout.split('\n') );
    });

  }

  var fileset = [ ];

  /*  Routes are in a file/list of files - set the fileset.  */
  if (routes  &&  routes.files) {
    fileset = routes.files;

    /*  Single file name - convert to a list w/ 1 entry.  */
    if ('string' === typeof routes.files) {
      fileset = [ routes.files ];
    }
  }

  /*  Invoke the callback w/ the list/set of files.  */
  return callback(fileset);

};  /*  End of function  _asyncLoadRouteFiles.  */


/*!
 *  }}}  //  End of section  Internal-Functions.
 *  ---------------------------------------------------------------------
 */



/*!  {{{  section:  'External-API-Functions'                             */

/**
 *  Constructs a new RequestSurrogate instance.
 *
 *  Examples:
 *    var s = new RequestSurrogate(req, res);
 *
 *  @param   {ServerRequest}     HTTP Server Request
 *  @param   {ServerResponse}    HTTP Server Response
 *  @return  {RequestSurrogate}  new RequestSurrogate instance.
 *  @api     public
 */
function RequestSurrogate(req, res) {
  this.client = {
    'request' : req,
    'response': res
  };

  this.backend = { };

  return this;

};  /*  End of function  RequestSurrogate (constructor).  */


/**
 *  Inherit from EventsEmitter - this needs to be done before we add
 *  any methods to the prototype. As util.inherits clobbers and
 *  overlays RequestSurrogate.prototoype in the call below.
 */
util.inherits(RequestSurrogate, events.EventEmitter);


/**
 *  Attach outgoing request/response to this RequestSurrogate.
 *
 *  Examples:
 *    var s = new RequestSurrogate(req, res);
 *    s.setBackendInfo(preq, pres);
 *
 *  @param  {ClientRequest}   HTTP Client Request
 *  @param  {ClientResponse}  HTTP Client Response
 *  @api    public
 */
RequestSurrogate.prototype.setBackendInfo = function(preq, pres) {
  this.backend.request  = preq;
  this.backend.response = pres;

};  /*  End of function  setBackendInfo.  */



/**
 *  Constructs a new WebSocketSurrogate instance.
 *
 *  Examples:
 *    var s = new WebSocketSurrogate(ws);
 *
 *  @param   {WebSocket}           WebSocket request.
 *  @return  {WebSocketSurrogate}  new WebSocketSurrogate instance.
 *  @api     public
 */
function WebSocketSurrogate(ws) {
  this.backend = { };
  this.client  = { };
  this.buffer  = [];

  this.client.websocket = ws;

  return this;

};  /*  End of function  WebSocketSurrogate (constructor).  */


/**
 *  Inherit from EventsEmitter - this needs to be done before we add
 *  any methods to the prototype. As util.inherits clobbers and
 *  overlays WebSocketSurrogate.prototoype in the call below.
 */
util.inherits(WebSocketSurrogate, events.EventEmitter);


/**
 *  Attach proxy websocket to this WebSocketSurrogate.
 *
 *  Examples:
 *    var s = new WebSocketSurrogate(ws);
 *    s.setBackendInfo(proxy_ws);
 *
 *  @param  {WebSocket}  Outbound WebSocket
 *  @api    public
 */
WebSocketSurrogate.prototype.setBackendInfo = function(ws) {
  this.backend.websocket = ws;

};  /*  End of function  setBackendInfo.  */



/**
 *  Constructs a new ProxyServer instance.
 *
 *  Examples:
 *    var cfgfile      = '/etc/openshift/web-proxy.json'
 *    var proxy_server = new ProxyServer.ProxyServer(cfgfile);
 *
 *  @param   {String}       Configuration file name/path.
 *  @return  {ProxyServer}  new ProxyServer instance.
 *  @api     public
 */
function ProxyServer(f) {
  this.proto_servers  = { };
  this.ws_servers     = { };
  this.loggers        = { };
  this.routes         = new ProxyRoutes.ProxyRoutes();
  this.initialized    = false;
  this._debug         = false;

  /*  Ensure configuration file exists.  */
  if (!f  ||  !(fs.statSync(f).isFile()) ) {
    throw new Error("Invalid config file '" + f + "' - file not found");
  }

  /*  Set the proxy server's config file and load the configuration.  */
  this.cfgfile  = f;
  this.config   = _load_config(this.cfgfile);

  /*  Setup a signal handler to load routes on a SIGHUP.  */
  var srvr = this;
  process.on('SIGHUP', function() { srvr.loadRoutes(); });

  /*  Setup a signal handler for debugging - dump routes on a SIGUSR1.  */
  process.on('SIGUSR1', function() {
    for (var n in srvr.routes.routes) {
      console.log('DEBUG: Host: ' + n + '  => Route : ' +
                  JSON.stringify(srvr.routes.routes[n]));
    }
  });

  /*  Setup a signal handler for toggling debugging - on a SIGUSR2.  */
  process.on('SIGUSR2', function() {
    var dbg = srvr.debug();  /*  Toggle current state.  */
    dbg = !dbg;
    srvr.debug(dbg);
    console.log('DEBUG: Got SIGUSR2, proxy server debug is now ' + dbg);
    Logger.info('Got SIGUSR2 - proxy server debug is now ' + dbg);
  });

  /*  Return a newly constructed ProxyServer instance.  */
  return this;

};  /*  End of function  ProxyServer (constructor).  */


/**
 *  Inherit from EventsEmitter - this needs to be done before we add
 *  any methods to the prototype. As util.inherits clobbers and
 *  overlays ProxyServer.prototoype in the call below.
 */
util.inherits(ProxyServer, events.EventEmitter);


/**
 *  Turn ON/OFF server debugging and return current debug state.
 *
 *  Examples:
 *    var cfgfile      = '/etc/openshift/web-proxy.json'
 *    var proxy_server = new ProxyServer.ProxyServer(cfgfile);
 *    proxy_server.debug(true);
 *    proxy_server.debug();  //  =>  true
 *
 *  @param   {Boolean}  true or false to turn debugging ON/OFF.
 *                      If undefined, just return current debug state.
 *  @return  {Boolean}  Current server debugging state.
 *  @api     public
 */
ProxyServer.prototype.debug = function(d) {
  if ('undefined' !== typeof d) {
    this._debug = d;
    var lvl = d ? 'DEBUG' : 'INFO';
    Logger.get().setLevel(lvl);
  }

  return this._debug;

};  /*  End of function  debug.  */


/**
 *  Gets the routes (endpoints) associated with the specified 'name'
 *  (port/virtual host/alias).
 *
 *  Examples:
 *    var cfgfile      = '/etc/openshift/web-proxy.json'
 *    var proxy_server = new ProxyServer.ProxyServer(cfgfile);
 *    proxy_server.initServer();
 *    proxy_server.getRoute('app1-ramr.rhcloud.com');
 *    proxy_server.getRoute(35753);
 *
 *  @param   {String}  External route name/info (virtual host/alias name).
 *  @return  {Array}   Associated endpoints/routes.
 *  @api     public
 */
ProxyServer.prototype.getRoute = function(host, path) {
  var path_segments = path.split('/');
  var max_segs = path_segments.length > 3? path_segments.length : 3;

  if (!this.routes)
    return this.routes;

  for (i = max_segs; i > 0; i--) {
    candidate_path = path_segments.slice(0, i).join('/');
    full_path = host + candidate_path;
    dest = this.routes.get(full_path);
    if (dest.length > 0) {
      dret = [];
      for (idx in dest) { dret.push(dest[idx] + ":" + candidate_path); }
      return dret;
    }
  }

  return [ ];
};  /*  End of function  getRoute.  */


/**
 *  Loads all the routes (endpoints) specified in the configuration for
 *  this ProxyServer instance.
 *
 *  Examples:
 *    var cfgfile      = '/etc/openshift/web-proxy.json'
 *    var proxy_server = new ProxyServer.ProxyServer(cfgfile);
 *    proxy_server.loadRoutes();
 *
 *  @api  public
 */
ProxyServer.prototype.loadRoutes = function() {
  /*  Coalesce loads if there's already a load in progress.  */
  if (this._coalesce_loads) {
    this._coalesce_loads += 1;
    return;
  }

  /*  Set load in progress indicator.  */
  this._coalesce_loads = 1;

  var self = this;

  /*  Asynchronously load routes specified in our configuration file.  */
  _asyncLoadRouteFiles(this.config.routes, function(route_files) {
    /*  Coalesce current loads.  */
    self._coalesce_loads = 1;

    /*  Create new routing table instance and load it w/ all the routes.  */
    var rtab = new ProxyRoutes.ProxyRoutes();
    route_files.forEach(function(f) { rtab.load(f); });

    /*  Replace the existing routes with the newly loaded routes.  */
    delete self.routes;
    self.routes = rtab;
    Logger.info('Routing information was reloaded');

    /*  Check if another loadRoutes request happened in the meantime.  */
    var need_a_reload = (self._coalesce_loads > 1);
    delete self._coalesce_loads;

    /*  Schedule a reload if it is required.  */
    if (need_a_reload) {
      /*  Run a loadRoutes in the background.  */
      setTimeout(self.loadRoutes, 2000);
    }

  });

};  /*  End of function  loadRoutes.  */

/**
 *  Gets the idle gear UUID associated with the specified 'name' or ""
 *  (port/virtual host/alias).
 *
 *  Examples:
 *    var cfgfile      = '/etc/openshift/web-proxy.json'
 *    var proxy_server = new ProxyServer.ProxyServer(cfgfile);
 *    proxy_server.initServer();
 *    proxy_server.getIdle('app1-ramr.rhcloud.com');
 *    proxy_server.getIdle(35753);
 *
 *  @param   {String}  External route name/info (virtual host/alias name).
 *  @return  {String}  Idled gear UUID or "" if not idled
 *  @api     public
 */
ProxyServer.prototype.getIdle = function (dest) {
  return((this.routes) ? this.routes.getIdle(dest) : "");
};  /*  End of function  getIdle.  */


/**
 *  Mark gear UUID associated with the specified 'name' as unidled
 *  (port/virtual host/alias).
 *
 *  Examples:
 *    var cfgfile      = '/etc/openshift/web-proxy.json'
 *    var proxy_server = new ProxyServer.ProxyServer(cfgfile);
 *    proxy_server.initServer();
 *    proxy_server.unIdle('app1-ramr.rhcloud.com');
 *    proxy_server.unIdle(35753);
 *
 *  @param   {String}  External route name/info (virtual host/alias name).
 *  @api     public
 */
ProxyServer.prototype.unIdle = function (dest) {
  return((this.routes) ? this.routes.unIdle(dest) : "");
};  /*  End of function  unIdle.  */

/**
 *  Initializes this ProxyServer instance.
 *
 *  Examples:
 *    var cfgfile      = '/etc/openshift/web-proxy.json'
 *    var proxy_server = new ProxyServer.ProxyServer(cfgfile);
 *    proxy_server.initServer();
 *
 *  @api  public
 */
ProxyServer.prototype.initServer = function() {
  Logger.info('Initializing ProxyServer ... ');

  /*  Setup loggers.  */
  for (var l in this.config.loggers) {
    this.loggers[l] = new Logger.Logger(l, this.config.loggers[l]);
  }


  /*  Stop the server and set up the routing table.  */
  this.stop();
  this.debug()  &&  Logger.debug('Loading routes ...');
  this.loadRoutes();
  this.debug()  &&  Logger.debug('Loaded routes');

  var self = this;

  /*  Initialize the listeners/handlers we proxy from.  */
  for (var s in this.config.servers) {
    /*  Create a new server for handling the specific protocol.  */
    Logger.info('Creating protocol server for ' + s);
    var maxconn = this.config.servers[s].max_connections;
    var proto   = this.config.servers[s].protocol;
    var opts    = this.config.servers[s].ssl;
    var srvr    = httputils.createProtocolServer(proto, opts);

    /*  Max number of listeners per event.  */
    srvr.setMaxListeners(maxconn);

    /*  Handle protocol server connection events.  */
    srvr.on('connection', function(conn) {
      self.debug()  &&  Logger.debug('server %s proto=%s - NEW connection',
                                     s, proto);
    });

    /*  Handle protocol server request events.  */
    srvr.on('request', function(req, res) {
      self.debug()  &&  Logger.debug('server %s proto=%s - new request %s',
                                     s, proto, req.url);
      _requestHandler(self, req, res);
    });

    /*  Create a websocket handler/server.  */
    Logger.info('Creating websocket server for ' + s);
    var wssrvr = new WebSocket.Server({server: srvr});

    /*  Handle a new websocket connection event.  */
    wssrvr.on('connection', function(ws) {
      self.debug()  &&  Logger.debug('server %s proto=%s ws request %s',
                                     s, proto, ws.upgradeReq.url);
      _websocketHandler(self, ws);
    });

    this.proto_servers[s]  = srvr;
    this.ws_servers[s] = wssrvr;
  }

  /*  This server is on fire!!  */
  Logger.info('Initialized ProxyServer');
  this.initialized = true;

};  /*  End of function  initServer.  */


/**
 *  Start this ProxyServer isntance - starts all the protocol handling
 *  servers we control.
 *
 *  Examples:
 *    var cfgfile      = '/etc/openshift/web-proxy.json'
 *    var proxy_server = new ProxyServer.ProxyServer(cfgfile);
 *    proxy_server.start();
 *
 *  @api  public
 */
ProxyServer.prototype.start = function() {
  /*  Initialize this ProxyServer instance if not already done.  */
  this.initialized  ||  this.initServer();

  Logger.info('Starting protocol servers for: ' +
              Object.keys(this.proto_servers));

  var self = this;

  var nlisteners = 0;

  /*  Count the number of listeners we have.  */
  for (var pname in this.proto_servers) {
    nlisteners += this.config.servers[pname].ports.length;
  }


  var switchUser = function() {
    if ((0 === process.getuid())  &&  (0 ===  process.getgid()) ) {
      process.setgid(self.config.runas.group);
      process.setuid(self.config.runas.user);
    }
  };

  /*  Start all the protocol handling servers - listen on ports.  */
  var lcnt = 0;
  for (var pname in this.proto_servers) {
    Logger.info('Starting protocol handler for ' + pname + ' ...');

    this.config.servers[pname].ports.forEach(function(port) {
      var host = self.config.servers[pname].host;
      try {
        self.proto_servers[pname].listen(port, host, function() {
          /*  Listen succeeded - write pid file.  */
          Logger.info(pname + ' listening on ' + host + ':' + port);
          fs.writeFileSync(self.config.pidfile, process.pid);
          lcnt += 1;
          (lcnt == nlisteners)  &&  switchUser();
        });

      } catch(err) {
        Logger.error(pname + ' failed to listen on '  + host + ':' + port);
      }

    });

  }

};  /*  End of function  start.  */


/**
 *  Stops this ProxyServer isntance - stops all the protocol handling
 *  servers we control.
 *
 *  Examples:
 *    var cfgfile      = '/etc/openshift/web-proxy.json'
 *    var proxy_server = new ProxyServer.ProxyServer(cfgfile);
 *    proxy_server.start();
 *    proxy_server.stop();
 *
 *  @api  public
 */
ProxyServer.prototype.stop = function() {
  Logger.info('Stopping protocol servers for: ' +
              Object.keys(this.proto_servers) );

  for (var pname in this.proto_servers) {
    try {
      this.proto_servers[pname].close();
      Logger.info('Stopped protocol handler for ' + pname);

    } catch(err) {
      Logger.error("Failed to stop protocol server '" + pname + "'.");
    }
  }

};  /*  End of function  stop.  */


/*!
 *  }}}  //  End of section  External-API-Functions.
 *  ---------------------------------------------------------------------
 */



/*!  {{{  section: 'Module-Exports'                                      */

exports.ProxyServer        = ProxyServer;
exports.RequestSurrogate   = RequestSurrogate;
exports.WebSocketSurrogate = WebSocketSurrogate;

/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */



/**
 *  EOF
 */
