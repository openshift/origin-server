var constants = require('constants');
var fs        = require('fs');
var http      = require('http');
var https     = require('https');


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
      var ssl_opts  = {
        secureOptions: constants.SSL_OP_NO_SSLv3
      };
      ssl_opts.ca   = fs.readFileSync(opts.ca);
      ssl_opts.cert = fs.readFileSync(opts.certificate);
      ssl_opts.key  = fs.readFileSync(opts.private_key);
      ssl_opts.honorCipherOrder = true;
      ssl_opts.ciphers = opts.ciphers || "kEECDH:+kEECDH+SHA:kEDH:+kEDH+SHA:+\
          kEDH+CAMELLIA:kECDH:+kECDH+SHA:kRSA:+kRSA+SHA:+kRSA+\
          CAMELLIA:!aNULL:!eNULL:!SSLv2:!RC4:!DES:!EXP:!SEED:!IDEA:+3DES";

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


/**
 *  Returns the user name associated with/in an Authorization header.
 *
 *  Examples:
 *    httputils.getAuthUserName(req.headers);
 *
 *  @param   {Dict}    Headers
 *  @return  {String}  Associated user name for an HTTP request with
 *                     an 'Authorization' header.
 *  @api     public
 */
exports.getAuthUserName = function(headers) {
  var auth = '  ';

  try {
    headers  &&  (auth = headers['Authorization']);

    var parts = auth.split(' ');
    var zbuf = new Buffer(parts[1], 'base64');
    return zbuf.toString().split(':')[0];

  } catch(err) {
  }

  return undefined;

}  /*  End of function  getAuthUserName.  */


/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */



/**
 *  EOF
 */
