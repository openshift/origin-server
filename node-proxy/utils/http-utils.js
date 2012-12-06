var fs    = require('fs');
var http  = require('http');
var https = require('https');


/*!  {{{  section: 'Module-Exports'                                      */

/**
 *  Creates a protocol handling server for the specified protocol.
 *
 *  Examples:
 *    httputils.createProtocolServer('http');
 *    var opts = { 'certificate': '/tmp/localhost.crt',
 *                 'private_key': '/tmp/localhost.key' };
 *    httputils.createProtocolServer('https', opts);
 *
 *  @param   {String}  Protocol (http or https).
 *  @param   {Dict}    Dictionary containing ssl options.
 *  @return  {Server}  Server instance handling the http|https protocol.
 *  @api     public
 */
exports.createProtocolServer = function(protocol, opts) {
  var proto_handler = undefined;

  switch(protocol) {
    case 'http':
      proto_handler = http.createServer();
      break;
    case 'https': 
      var ssl_opts  = { };
      ssl_opts.cert = fs.readFileSync(opts.certificate);
      ssl_opts.key  = fs.readFileSync(opts.private_key);
      proto_handler = https.createServer(ssl_opts);
      break;
  }

  return proto_handler;

}  /*  End of function  createProtocolServer.  */


/**
 *  Adds or appends the specified value to an HTTP header.
 *
 *  Examples:
 *    httputils.addHeader(rsp.headers, 'Server', 'node-http-ws-proxy/0.1');
 *
 *  @param   {Dict}    Headers (I/O parameter).
 *  @param   {String}  HTTP header name.
 *  @param   {String}  Header value to add/set.
 *  @return  {Dict}    Modified headers.
 *  @api     public
 */
exports.addHeader = function(headers, n, v) {
  headers[n] = (headers[n])? (headers[n] + ', ' + v) : v;
  return headers;

}  /*  End of function  addHeader.  */


/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */



/**
 *  EOF
 */
