var constants = require('./constants.js');


/*!  {{{  section: 'Module-Exports'                                      */

/**
 *  Return a service unavailable (503) error page.
 *
 *  Examples:
 *    error_pages.service_unavailable_page('app1-ramr.rhcloud.com', 8000);
 *
 *
 *  @param   {String}   Host name (virtual host/alias name).
 *  @param   {Integer}  Port number.
 *  @return  {String}   a service unavailable (503) error page.
 *  @api     public
 */
exports.service_unavailable_page = function(host,port) {
  var I_AM = constants.NODE_PROXY_WEB_PROXY_NAME + '/' +
             constants.NODE_PROXY_PRODUCT_VER;
  var p = [
    '<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">\n', 
    '<HTML>\n',
    '  <HEAD><TITLE>503 Service Temporarily Unavailable</TITLE></HEAD>\n',
    '  <BODY>\n',
    '    <H1>Service Temporarily Unavailable</H1>\n',
    '    <P>\n',
    '      The server you are trying to contact is down either because\n',
    '      it was stopped or is unable to service your request due to\n',
    '      maintenance downtime or capacity problems.\n',
    '      Please try again later.\n',
    '   </P>\n',
    '   <HR>\n',
    '   <address>', I_AM, ' Server at ', host, ' Port ', port,
    '   </address>\n',
    ' </BODY>\n',
    '<HTML>\n'
  ].join('');

  return p;

}  /*  End of function  service_unavailable_page.  */


/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */



/**
 *  EOF
 */
