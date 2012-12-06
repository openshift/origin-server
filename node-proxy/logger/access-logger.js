var path = require('path');
var fs   = require('fs');
var util = require('util');

/*  load in Logger and date utils.  */
var Logger    = require('./Logger.js');
var dateutils = require('../utils/date-utils.js');


/*!  {{{  section:  'Private-Variables'                                  */

var _access_logger = 'access.log';

/*!
 *  }}}  //  End of section  Private-Variables.
 *  ---------------------------------------------------------------------
 */


/*!  {{{  section: 'Internal-Functions'                                 */

function _getTimeZoneOffset() {
  var now     = new Date(Date.now() );
  var zoffset = Math.abs(now.getTimezoneOffset() );
  var zsign   = "";

  zsign = (zoffset > 0)? "-" : ((zoffset < 0)? "+" : "");

  var offset_in_hrs = Math.abs(zoffset/60);
  var num_hrs       = parseInt(offset_in_hrs);
  var num_mins      = parseInt((offset_in_hrs - num_hrs) * 60);

  return zsign + ('0' + num_hrs).slice(-2) + ('0' + num_mins).slice(-2);

}  /*  End of function  _getTimeZoneOffset.  */


function _getAuthUser(req) {
  var auth = '  ';
  req  &&  req.headers  &&  (auth = req.headers['Authorization']);

  try {
    var parts = auth.split(' ');
    var zbuf = new Buffer(parts[1], 'base64');
    return  zbuf.toString().split(':')[0];
  } catch(err) {
  }

  return undefined;

}  /*  End of function  _getAuthUser.  */


/*!
 *  }}}  //  End of section  Internal-Functions.
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
  var auth_user      = _getAuthUser(req)  ||  '-';
  var tzoffset       = _getTimeZoneOffset();
  var protocol       = 'http';
  var nbytes         = metrics.bytes_out;
  var req_time_ms    = metrics.end - metrics.start;
  var response_ka    = '';
  if (res.headers  &&  res.headers['connection']) {
     response_ka = res.headers['connection'];
  }

  var keepalive_flag = '-';  /*  X = aborted , += keep-alive, -= closed  */
  var referer        = req.headers['referer']  ||  '-';
  var user_agent     = req.headers['user-agent']  ||  '-';

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
   *  Log an apache style access log message.
   *  Example:
   *    209.132.181.86 nodescale-rr64.dev.rhcloud.com - -                  \
   *    [04/Dec/2012:18:47:03 -0500] "GET /favicon.ico HTTP/1.1"           \
   *    404 41 "-"                                                         \
   *    " Lynx/2.8.6rel.5 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/1.0.0-fips"  \
   *    (42ms) +
   */
  var zmsg = util.format('%s %s %s %s [%s] "%s" %d %d "%s" "%s" (%dms) %s',
                         remote_host, vhost, remote_login, auth_user,
                         ap_times, req_info,
                         res.statusCode, metrics.bytes_out, referer,
                         user_agent,
                         req_time_ms, keepalive_flag);
  /**
   *  TODO:  This is still work to be done. 
   *  console.log(zmsg);
   *  return getAccessLogger().info(zmsg);
   */


}  /*  End of function  logAccess.  */


/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */


/**
 *  EOF
 */
