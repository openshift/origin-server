var path          = require('path');
var fs            = require('fs');
var util          = require('util');
var events        = require('events');
var http          = require('http');
var https         = require('https');
var WebSocket     = require('ws');
var child_process = require('child_process');

var ProxyRoutes = require('./ProxyRoutes.js');
var constants   = require('../utils/constants.js');
var httputils   = require('../utils/http-utils.js');
var statuscodes = require('../utils/status-codes.js');
var errorpages  = require('../utils/error-pages.js');
var Logger      = require('../logger/Logger.js');

/*!  {{{  section:  'Private-Variables'                                  */

/*  Default timeouts.  */
var DEFAULT_IO_TIMEOUT         = 300;   /*  5 minutes (300 secs).  */
var DEFAULT_WEBSOCKETS_TIMEOUT = 3600;  /*  1 hour (3600 secs).    */

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
 *      _setProxyResponseHeaders(pres, 'app1-ramr.rhcloud.com');
 *    });
 *
 *  @param  {http.ClientResponse}  Response from the proxied request.
 *  @api    private
 */
function _setProxyResponseHeaders(proxy_res, vhost) {
  var about_me = constants.NODE_PROXY_WEB_PROXY_NAME + '/' +
                 constants.NODE_PROXY_PRODUCT_VER;
  var zroute   = '1.1 ' + vhost + ' (' + about_me + ')';

  /*  We only set the Via: header to indicate it went via us.  */
  httputils.addHeader(proxy_res.headers, 'Via', zroute);

}  /*  End of function  _setProxyResponseHeaders.  */


/**
 *  Set the request headers on the proxied request. 
 *
 *  Examples:
 *    var preq = http.request(proxy_req, function(pres) {
 *      _setProxyResponseHeaders(pres, 'app1-ramr.rhcloud.com');
 *    });
 *
 *  @param  {http.ClientRequest}  The request we send to the endpoint.
 *  @param  {http.ServerRequest}  The request we received. 
 *  @api    private
 */
function _setProxyRequestHeaders(proxy_req, orig_req) {
  /*  Set X-Forwarded-For HTTP extension header.  */
  var xff = orig_req.connection.RemoteAddress  || 
            orig_req.socket.RemoteAddress;
  httputils.addHeader(proxy_req.headers, 'X-Forwarded-For', xff);

  /*  Set X-Forwarded-Proto HTTP extension header.  */
  var proto = orig_req.connection.encrypted? 'https' : 'http';
  httputils.addHeader(proxy_req.headers, 'X-Forwarded-Proto', proto);

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
  /*  Request start event.  */
  proxy_server.emit('request.start', req);

  /*  Get the request/socket io timeout.  */
  var io_timeout = DEFAULT_IO_TIMEOUT;   /*  300 seconds.  */
  if (proxy_server.config.timeouts  &&  proxy_server.config.timeouts.io) {
    io_timeout = proxy_server.config.timeouts.io;
  }

  /*  Set timeout on the incoming request/socket.  */
  req.socket.setTimeout(io_timeout * 1000);  /*  Timeout is in ms.  */


  var reqhost = '';
  var reqport = 8000;

  /*  Get the host, the request was sent to.  */
  if (req.headers  &&  req.headers.host) {
    reqhost = req.headers.host.split(':')[0];
  }

  proxy_server.debug()  &&  Logger.debug('Handling HTTP[S] request to ' +
                                         reqhost);


  /*  Get the request URI.  */
  var request_uri = req.url ? req.url : '/';


  /*  Get the routes to the destination (try with request URI first).  */
  var routes = proxy_server.getRoute(reqhost + request_uri);
  if (routes.length < 1) {
    /*  No specific route, try the more general route.  */
    routes = proxy_server.getRoute(reqhost);
  }

  /*  No route, no milk [, no cookies] ... return a temporary redirect.  */
  if (!routes  ||  (routes.length < 1)  ||  (routes[0].length < 1) ) {
    /*  Request routing error event.  */
    proxy_server.emit('request.route.error', req, res);

    /*  Send a temporary redirect to the 404 redirect location.  */
    res.statusCode = statuscodes.HTTP_TEMPORARY_REDIRECT;
    res.setHeader('Location', proxy_server.config.routes.redirect404);
    res.end('');
    return;
  }

  /*  Get the endpoint we need to send this request to.  */
  var ep = routes[0].split(':');
  var ep_host = ep[0];
  var ep_port = ep[1] || 8080;

  proxy_server.debug()  &&  Logger.debug('Sending a proxy request to %s', ep);

  /*  Create a proxy request we need to send & set appropriate headers.  */
  var proxy_req = { host: ep_host, port: ep_port,
                    method: req.method, path: request_uri,
                    headers: req.headers
                  };
  _setProxyRequestHeaders(proxy_req, req);

  var preq  = http.request(proxy_req, function(pres) {
    /*  Proxy response start event.  */
    proxy_server.emit('proxy-response.start', req, res, preq, pres);

    /*  Handle the proxy response error/end/data events.  */
    pres.addListener('error', function() {
      /*  Proxy response error event.  */
      proxy_server.emit('proxy-response.error', req, res, preq, pres);

      /*  Finish the response to the originating request.  */
      res.end();
    });

    pres.addListener('end', function() {
      /*  Proxy response end event.  */
      proxy_server.emit('proxy-response.end', req, res, preq, pres);

      /*  Finish the response to the originating request.  */
      res.end();
    });

    pres.addListener('data', function(chunk) {
      /*  Proxy response data event.  */
      proxy_server.emit('proxy-response.data', req, res, preq, pres);

      /*  Proxy response to the request originator.  */
      res.write(chunk);
    });

    /*  Set the appropriate headers on the reponse & send the headers.  */
    _setProxyResponseHeaders(pres, reqhost);
    res.writeHead(pres.statusCode, pres.headers);
  });

  /*  Handle the outgoing request socket event and set a timeout.  */
  preq.on('socket', function(socket) {
    socket.setTimeout(io_timeout * 1000);  /*  Timeout is in ms.  */
    socket.on('timeout', function() {
      preq.abort();
    });
  });

// preq.setTimeout(io_timeout * 1000);  /*  Timeout is in milliseconds.  */

  /*  Handle the incoming request error/end/data events.  */
  req.addListener('error', function() {
    /*  Request error event.  */
    proxy_server.emit('request.error', req, res, preq);

    /*  Finish the proxied request and return a 503.  */
    preq.abort();
    res.statusCode = statuscodes.HTTP_SERVICE_UNAVAILABLE;
    res.write(errorpages.service_unavailable_page(reqhost, reqport) );
    res.end();
  });

  req.addListener('end', function() {
    /*  Request normal end event.  */
    proxy_server.emit('request.end', req, res, preq);

    /*  Finish the outgoing request to the backend content server.  */
    preq.end();
  });

  req.addListener('data', function(chunk) {
    /*  Request data event.  */
    proxy_server.emit('request.data', req, res, preq);

    /*  Proxy data to outgoing request to the backend content server.  */
    preq.write(chunk);
  });


  /*  Handle the outgoing request error event.  */
  preq.addListener('error', function() {
    proxy_server.emit('proxy-request.error', req, res, preq);

    /*  Finish the incoming request and return a 503.  */
    // RR: req.end();
    res.statusCode = statuscodes.HTTP_SERVICE_UNAVAILABLE;
    res.write(errorpages.service_unavailable_page(reqhost, reqport) );
    res.end('');
  });

};  /*  End of function  requestHandler.  */


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
  /*  Websocket start event.  */
  proxy_server.emit('websocket.start', ws);

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

  /*  Get the original request URI.  */
  var upg_requri = upgrade_req.url ? upgrade_req.url : '/';

  /*  Get the routes to the destination (try with request URI first).  */
  var routes = proxy_server.getRoute(upg_reqhost + upg_requri);
  if (routes.length < 1) {
    /*  No specific route, try the more general route.  */
    routes = proxy_server.getRoute(upg_reqhost);
  }

  /*  No route, no milk [, no cookies] ... return unexpected condition.  */
  if (!routes  ||  (routes.length < 1)  ||  (routes[0].length < 1) ) {
    /*  Websocket routing error event.  */
    proxy_server.emit('websocket.route.error', ws);

    /*  Send an unexpected condition error - no route.  */
    return ws.close(statuscodes.WS_UNEXPECTED_CONDITION,
                    proxy_server.config.routes.redirect_missing);
  }


  var ws_endpoint = routes[0];

  proxy_server.debug()  &&  Logger.debug('Sending a websocket request to %s',
                                         ws_endpoint);

  /*  Create a proxy websocket request we need to send.  */
  var proxy_ws = new WebSocket('ws://' + ws_endpoint + upg_requri);

  /*  Handle the proxy websocket error/open/close/message events.  */
  proxy_ws.on('error', function(err) {
    /*  Websocket proxy error event.  */
    proxy_server.emit('websocket.proxy.error', ws, proxy_ws);

    /*  Finish the websocket request w/ an unexpected condition status.  */
    ws.close(errorpages.WS_UNEXPECTED_CONDITION);
    proxy_ws.terminate();
  });

  proxy_ws.on('open', function() {
    /*  Websocket proxy open event.  */
    proxy_server.emit('websocket.proxy.open', ws, proxy_ws);
  });

  proxy_ws.on('close', function() {
    /*  Websocket proxy close event.  */
    proxy_server.emit('websocket.proxy.close', ws, proxy_ws);

    /*  Finish the websocket request normally.  */
    ws.close(errorpages.WS_NORMAL_CLOSURE);
  });

  proxy_ws.on('message', function(data, flags) {
    /*  Websocket proxy data/message event.  */
    proxy_server.emit('websocket.proxy.message', ws, proxy_ws);

    /*  Proxy message back to the websocket request originator.  */
    ws.send(data, flags);
  });

  /*  Handle the incoming websocket error/close/message events.  */
  ws.on('error', function() {
    /*  Websocket error event.  */
    proxy_server.emit('websocket.error', ws, proxy_ws);

    /*  Finish the websocket request w/ an unexpected condition status.  */
    proxy_ws.close(errorpages.WS_UNEXPECTED_CONDITION);
    ws.terminate();
  });

  ws.on('close', function() {
    /*  Websocket close event.  */
    proxy_server.emit('websocket.end', ws, proxy_ws);

    /*  Finish the websocket request normally.  */
    proxy_ws.close(errorpages.WS_NORMAL_CLOSURE);
  });

  ws.on('message', function(data, flags) {
    /*  Websocket data/message event.  */
    proxy_server.emit('websocket.message', ws, proxy_ws);

    /*  Proxy data to outgoing websocket to the backend content server.  */
    proxy_ws.send(data, flags);
  });

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
    return child_process.exec(routes.cmd, function(err, stdout, stderr) {
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
ProxyServer.prototype.getRoute = function(dest) {
  return((this.routes)? this.routes.get(dest) : [ ]);

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
    var proto = this.config.servers[s].protocol;
    var opts  = this.config.servers[s].ssl;
    var srvr = httputils.createProtocolServer(proto, opts);

    /*  Handle protocol server connection events.  */
    srvr.on('connection', function(conn) {
      self.debug()  &&  Logger.debug('server %s proto=%s - NEW connection',
                                     s, proto);
    });

    /*  Handle protocol server request events.  */
    srvr.on('request', function(req, res) {
      self.debug()  &&  Logger.debug('server %s proto=%s - new request %s',
                                     s, proto, req.url);
      /* TODO: Add max connections support via config.  */
      srvr.setMaxListeners(0);
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

  /*  Start all the protocol handling servers - listen on ports.  */
  for (var pname in this.proto_servers) {
    Logger.info('Starting protocol handler for ' + pname + ' ...');

    this.config.servers[pname].ports.forEach(function(port) {
      try {
        self.proto_servers[pname].listen(port, undefined, function() {
          /*  Listen succeeded - write pid file.  */
          Logger.info(pname + ' listening on port ' + port);
          fs.writeFileSync(self.config.pidfile, process.pid);
        });

      } catch(err) {
        Logger.error(pname + ' failed to listen to port ' + port);
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



/*  TODO:  No events support as yet -- for now, this is just for debugging. */

/*  Inherit events from EventEmitter.  */
// util.inherits(ProxyServer, events.EventEmitter);
ProxyServer.prototype.emit = function(event, args) {
  if (event  &&  (0 != event.indexOf('websocket.message'))  &&
      (0 != event.indexOf('websocket.proxy') ) ) {
    /*  Supress websocket "noise".  */
    this.debug()  &&  Logger.debug('Proxy server emitted EVENT = ' + event);
  }

};


/*!
 *  }}}  //  End of section  External-API-Functions.
 *  ---------------------------------------------------------------------
 */



/*!  {{{  section: 'Module-Exports'                                      */

exports.ProxyServer = ProxyServer;

/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */



/**
 *  EOF
 */
