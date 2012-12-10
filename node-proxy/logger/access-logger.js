var path = require('path');
var fs   = require('fs');
var util = require('util');

/*  load in Logger and date utils.  */
var Logger    = require('./Logger.js');
var httputils = require('../utils/http-utils.js');
var dateutils = require('../utils/date-utils.js');


/*!  {{{  section:  'Private-Variables'                                  */

var _access_logger = 'access.log';

/*!
 *  }}}  //  End of section  Private-Variables.
 *  ---------------------------------------------------------------------
 */



/*!  {{{  section: 'Module-Exports'                                      */

/**
 *  Return the access logger instance.
 *
 *  Examples:
 *    access_logger.get();  //  =>  Logger.get('access.log');
 *
 *  @return  {Logger}  Access Logger instance.
 *  @api     public
 */
var getAccessLogger = exports.get = function() {
  return Logger.get(_access_logger);

};  /*  End of function  get/getAccessLogger.  */


/**
 *  Logs an access.log message for the request.
 *
 *  Examples:
 *    access_logger.log(req, res, metrics);
 *
 *  @param   {ServerRequest}   Http ServerRequest object.
 *  @param   {ServerResponse}  Http ServerResponse object.
 *  @param   {Dict}            Dictionary of request metrics.
 *  @api     public
 */
exports.log = function(req, res, metrics) {
  var remote_host    = req.connection.remoteAddress  ||
                       req.socket.remoteAddress      ||  '-';
  var vhost          = req.headers.host.split(':')[0]  ||  '-';
  var remote_login   = '-';
  var auth_user      = httputils.getAuthUserName(req.headers)  ||  '-';
  var tzoffset       = dateutils.getTimeZoneOffset();
  var referer        = req.headers['referer']  ||  '-';
  var user_agent     = req.headers['user-agent']  ||  '-';
  var protocol       = 'http';
  var nbytes         = metrics.bytes_out;
  var req_time_ms    = metrics.end - metrics.start;

  var response_ka    = '';
  if (res.headers  &&  res.headers['connection']) {
     response_ka = res.headers['connection'];
  }


  var keepalive_flag = '-';  /*  X = aborted , += keep-alive, -= closed  */
  if (metrics.error) { 
    keepalive_flag = 'X';
  }
  else if ('keep-alive' === response_ka.toLowerCase() ) {
    keepalive = '+';
  }
   
  var req_info = util.format('%s %s %s/%s', req.method, req.url,
                             protocol.toUpperCase(), req.httpVersion);
  var ap_times = util.format('%s %s', dateutils.strftime('%d/%b/%Y:%T'),
                             tzoffset);

  /**
   *  Log a NCSA/apache style access log message.
   *  Example:
   *    209.132.181.15 nodescale-rr64.dev.rhcloud.com - -                  \
   *    [04/Dec/2012:18:47:03 -0500] "GET /favicon.ico HTTP/1.1"           \
   *    404 41 "-"                                                         \
   *    " Lynx/2.8.6rel.5 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/1.0.0-fips"  \
   *    (42ms) +
   */
  var zmsg = util.format('%s %s %s %s [%s] "%s" %d %d "%s" "%s" (%dms) %s\n',
                         remote_host, vhost, remote_login, auth_user,
                         ap_times, req_info,
                         res.statusCode, metrics.bytes_out, referer,
                         user_agent,
                         req_time_ms, keepalive_flag);

  return getAccessLogger().logMessage(zmsg, "INFO");

}  /*  End of function  logAccess.  */


/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */


/**
 *  EOF
 */
