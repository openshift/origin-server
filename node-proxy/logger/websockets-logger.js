var path = require('path');
var fs   = require('fs');
var util = require('util');

/*  load in Logger and date utils.  */
var Logger    = require('./Logger.js');
var httputils = require('../utils/http-utils.js');
var dateutils = require('../utils/date-utils.js');


/*!  {{{  section:  'Private-Variables'                                  */

var _ws_logger = 'websockets.log';

/*!
 *  }}}  //  End of section  Private-Variables.
 *  ---------------------------------------------------------------------
 */



/*!  {{{  section: 'Module-Exports'                                      */

/**
 *  Return the websocket logger instance.
 *
 *  Examples:
 *    ws_logger.get();  //  =>  Logger.get('websocket.log');
 *
 *  @return  {Logger}  WebSocket Logger instance.
 *  @api     public
 */
var getWebSocketsLogger = exports.get = function() {
  return Logger.get(_ws_logger);

};  /*  End of function  get/getWebSocketsLogger.  */


/**
 *  Logs an websocket.log message for the websocket request.
 *
 *  Examples:
 *    ws_logger.log(ws, metrics);
 *
 *  @param  {WebSocket}  Incoming WebSocket request.
 *  @api    public
 */
exports.log = function(ws, metrics) {
  var protocol       = ws.protocol  ||  "RFC-6455";
  var wsproto_info   = util.format("Websocket %s/%s", protocol,
                                   ws.protocolVersion);
  var tzoffset       = dateutils.getTimeZoneOffset();
  var ws_req_time_ms = metrics.end - metrics.start;
  var ap_times       = util.format('%s %s', dateutils.strftime('%d/%b/%Y:%T'),
                                   tzoffset);

  /*  Set error info to the status code or error.  */
  var err_info = metrics.status_code;
  if (metrics.error  &&  (metrics.error.length > 0)) {
    err_info = util.format('"%s"', + metrics.error);
  }

  var ws_metrics = util.format('msgs:%d,%d bytes:%d,%d',
                               metrics.messages_in, metrics.messages_out,
                               metrics.bytes_in, metrics.bytes_out);
  /**
   *  Log websocket message.
   *  Example:
   *    209.132.181.15 echo-ramr.dev.rhcloud.com [07/Dec/2012:19:09:44 -0500]  \
   *    "GET /wsecho/eh HTTP/1.1" "Websocket RFC-6455/13" 1000                 \
   *    "msgs:0,1 bytes:0,39" (337ms)
   */
  var msg = util.format('%s %s [%s] "%s" "%s" %s "%s" (%dms)\n',
                        metrics.remote_addr, metrics.host_name, ap_times,
                        metrics.request_info, wsproto_info, err_info,
                        ws_metrics, ws_req_time_ms);

  return getWebSocketsLogger().logMessage(msg, "INFO");

}  /*  End of function  log.  */


/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */


/**
 *  EOF
 */
