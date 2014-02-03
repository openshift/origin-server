var path = require('path');
var fs   = require('fs');
var util = require('util');
var http = require('http');

/*  load in Logger and date utils.  */
var Logger      = require('../logger/Logger.js');
var httputils   = require('../utils/http-utils.js');
var dateutils   = require('../utils/date-utils.js');
var statuscodes = require('../utils/status-codes.js');


/*!  {{{  section:  'Private-Variables'                                  */

/*  Access and websockets loggers.  */
var _access_logger = 'access.log';
var _ws_logger     = 'websockets.log';


/*!
 *  }}}  //  End of section  Private-Variables.
 *  ---------------------------------------------------------------------
 */



/*!  {{{  section: 'Internal-Functions'                                  */

/**
 * Format log message
 *
 * @param payload
 * @returns {*}
 * @private
 */
function _format(payload) {
  var remote_host    = payload.request.remoteaddr  ||  '-';
  var vhost          = payload.request.host ||  '-';
  var remote_login   = '-';
  var auth_user      = payload.request.authuser  ||  '-';
  var referer        = payload.request.referer  ||  '-';
  var user_agent     = payload.request.useragent  ||  '-';
  var req_time_ms    = payload.end - payload.start;
  var keepalive_flag = payload.response.keepalive;
  var req_info       = payload.request.reqinfo;
  var tzoffset       = dateutils.getTimeZoneOffset();
  var ap_times       = util.format('%s %s',
                                   dateutils.strftime('%d/%b/%Y:%T'),
                                   tzoffset);

  console.log("payload.websocket: " + payload.websocket);
  if (!(typeof(payload.websocket) === 'undefined')) {
    user_agent = payload.websocket.protoinfo;
  }

  /**
   *  Log a NCSA/apache style access log message.
   *  Example:
   *    209.132.181.15 nodescale-rr64.dev.rhcloud.com - -                  \
   *    [04/Dec/2012:18:47:03 -0500] "GET /favicon.ico HTTP/1.1"           \
   *    404 41 "-"                                                         \
   *    " Lynx/2.8.6rel.5 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/1.0.0-fips"  \
   *    (42ms) +
   */
  return util.format('%s %s %s %s [%s] "%s" %d %d "%s" "%s" (%dms) %s\n',
                     remote_host,
                     vhost.toLowerCase(),
                     remote_login,
                     auth_user,
                     ap_times,
                     req_info,
                     payload.response.code,
                     payload.metrics.bytes_out,
                     referer,
                     user_agent,
                     req_time_ms,
                     keepalive_flag)
}

/**
 *  Logs an access.log message for the handled request.
 *
 *  Examples:
 *    var payload = new PayloadInfo(req);
 *    // ...
 *    payload.complete(res);
 *    _log_access(payload);
 *
 *  @param  {PayloadInfo}  Payload information.
 *  @api    private
 */
function _log_access(payload) {
  return Logger.get(_access_logger).logMessage(_format(payload), "INFO");
}  /*  End of function  _log_access.  */


/**
 *  Logs an websocket.log message for the handled websocket request.
 *
 *  Examples:
 *    var payload = new PayloadInfo(ws);
 *    // ...
 *    payload.complete(statuscodes.WS_NORMAL_CLOSURE);
 *    _log_websocket_access(payload);
 *
 *  @param  {PayloadInfo}  Payload information.
 *  @api    private
 */
function _log_websocket_access(payload) {
  return Logger.get(_ws_logger).logMessage(_format(payload), "INFO");
}  /*  End of function  _log_websocket_access.  */


/**
 *  The payload info is really just a hash for the request and metrics and
 *  some meta info.
 *
 *  Examples:
 *    var m = new PayloadInfo(req);
 *
 *  @param  {ServerRequest|WebSocket}  the HTTP server request or websocket.
 *  @api    private
 */
function PayloadInfo(wsreq) {
  var wsproto    = '';
  var wsprotover = '';
  var reqhost    = '';

  var is_http_req = (typeof(wsreq.upgradeReq) === 'undefined');
  var req = is_http_req? wsreq : wsreq.upgradeReq;

  // https://bugzilla.redhat.com/show_bug.cgi?id=1030641
  if (req.headers  &&  req.headers.host) {
    reqhost = req.headers.host.split(':')[0];
  }
  /*  Initialize the request meta data.  */
  this.request = {
    'remoteaddr': req.connection.remoteAddress  || req.socket.remoteAddress,
    'host'      : reqhost,
    'authuser'  : httputils.getAuthUserName(req.headers),
    'referer'   : req.headers['referer'],
    'useragent' : req.headers['user-agent'],
    'reqinfo'   : util.format('%s %s HTTP/%s', req.method, req.url || '/',
                              req.httpVersion)
  };

  /*  And the websocket meta data.  */
  if (!is_http_req) {
    var  wsproto = wsreq.protocol  ||  "RFC-6455";
    this.websocket = {
      'protocol' : wsproto,
      'protoinfo': util.format("Websocket %s/%s", wsproto,
                               wsreq.protocolVersion)
    };
  }

  /*  Initialize the response meta data.  */
  this.response = {
     'keepalive': '',
     'code'     : statuscodes.WS_NORMAL_CLOSURE,
     'error'    : ''
  };

  /*  Timings.  */
  this.start = Date.now();
  this.end   = 0;

  /*  And finally the metrics.  */
  this.metrics = {
    'messages_in' : 0,
    'messages_out': 0,
    'bytes_in'    : 0,
    'bytes_out'   : 0
  };

}  /*  End of function  PayloadInfo.  */


/**
 *  Method called when the request/response completes.
 *
 *  Examples:
 *    var m = new PayloadInfo(req);
 *    m.complete();
 *
 *  @param  {ServerResponse|Integer}  the HTTP server response or WS status.
 *  @param  {String}                  error message if any.
 *  @api    public
 */
PayloadInfo.prototype.complete = function(res_or_code, error) {
  /*  Determine what's the keep alive indicator.  */
  var zcode = res_or_code;
  var ka   = '-';  /*  X = aborted , += keep-alive, -= closed  */

  if (typeof(res_or_code) !== 'number') {
    zcode = res_or_code.statusCode;
    res_or_code.shouldKeepAlive  &&  (ka = '+');
    error  &&  (ka = 'X');
  }

  /*  Set the response bits.  */
  this.response.code      = zcode;
  this.response.error     = error;
  this.response.keepalive = ka;

  /*  And set the time when the request/response completed. */
  this.end =  Date.now();

}  /*  End of function  complete.  */


/**
 *  Plug into proxy server events for normal HTTP requests. Registers handlers
 *  for {request,response}.* and proxy.{request,response}.* events.
 *
 *  Examples:
 *    _normal_request_workflow_plugin(proxy_server);
 *
 *  @param  {ProxyServer}  ProxyServer object.
 *  @api    private
 */
function _normal_request_workflow_plugin(proxy_server) {
  proxy_server.on('surrogate.request', function(surrogate) {
    /*  On request start - associate payload with the request.  */
    var payload = new PayloadInfo(surrogate.client.request);

    /*  Handle normal completion.  */
    surrogate.on('end', function() {
      payload.complete(surrogate.client.response);
      _log_access(payload);
    });

    /*  Handle errors.  */
    surrogate.on('error', function(err) {
      payload.complete(surrogate.client.response, err);
      _log_access(payload);
    });

    /*  Bean counters.  */
    surrogate.on('inbound.data', function(chunk) {
      /*  Increment inbound bytes.  */
      payload.metrics.bytes_in += chunk.length;
    });

    surrogate.on('outbound.data', function(chunk) {
      /*  Increment outbound bytes.  */
      payload.metrics.bytes_out += chunk.length;
    });

  });

}  /*  End of function  _normal_request_workflow_plugin.  */


/**
 *  Plug into proxy server events for websocket requests. Registers handlers
 *  for websocket.* and proxy.websocket.* events.
 *
 *  Examples:
 *    _websocket_workflow_plugin(proxy_server);
 *
 *  @param  {ProxyServer}  ProxyServer object.
 *  @api    private
 */
function _websocket_workflow_plugin(proxy_server) {

  proxy_server.on('surrogate.websocket', function(surrogate) {
    /*  On websocket start - associate payload with the request.  */
    var payload = new PayloadInfo(surrogate.client.websocket);

    /*  Handle normal completion.  */
    surrogate.on('end', function() {
      payload.complete(statuscodes.WS_NORMAL_CLOSURE);
      _log_websocket_access(payload);
    });

    /*  Handle errors.  */
    surrogate.on('error', function(err) {
      payload.complete(statuscodes.WS_UNEXPECTED_CONDITION, err);
      _log_websocket_access(payload);
    });

    /*  Bean counters.  */
    surrogate.on('inbound.data', function(data, flags) {
      /*  Increment number of inbound messages + bytes.  */
      payload.metrics.messages_in += 1;
      payload.metrics.bytes_in    += data.length;
    });

    surrogate.on('outbound.data', function(data, flags) {
      /*  Increment number of outbound messages + bytes.  */
      payload.metrics.messages_out += 1;
      payload.metrics.bytes_out    += data.length;
    });

  });

}  /*  End of function  _websocket_workflow_plugin.  */


/*!
 *  }}}  //  End of section  Internal-Functions.
 *  ---------------------------------------------------------------------
 */



/*!  {{{  section: 'Module-Exports'                                      */

/*  Name of this plugin.   */
exports.name = "RequestLoggerPlugin";


/**
 *  Intialize the AccessLoggerPlugin and plug into the request workflow -
 *  ProxyServer events.
 *
 *  Examples:
 *    var wsreq_logger = require('ws-request-logger.js');
 *    wsreq_logger.plugin(proxy_server);
 *
 *  @param  {ProxyServer}  ProxyServer object.
 *  @api    public
 */
exports.plugin = function(ps) {
  _normal_request_workflow_plugin(ps);
  _websocket_workflow_plugin(ps);

}  /*  End of function  AccessLoggerPlugin.  */


/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */


/**
 *  EOF
 */
