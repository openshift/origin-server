
/*!  {{{  section: 'Module-Exports'                                      */

/*  Temporary Redirect and Service Unavailable HTTP codes.  */
exports.HTTP_CONTINUE               = 100;   /*  Continue request.        */
exports.HTTP_OK                     = 200;   /*  HTTP OK/succeeded.       */
exports.HTTP_CREATED                = 201;   /*  Resource created.        */
exports.HTTP_ACCEPTED               = 202;   /*  Request accepted.        */
exports.HTTP_NON_AUTHORITATIVE_INFO = 203;   /*  Processed - information  */
                                             /*  from another source.     */
exports.HTTP_NO_CONTENT             = 204;   /*  No content.              */
exports.HTTP_RESET_CONTENT          = 205;   /*  Reset content.           */
exports.HTTP_PARTIAL_CONTENT        = 206;   /*  Partial GET/content.     */
exports.HTTP_MULTIPLE_CHOICES       = 300;   /*  Multiple choices.        */
exports.HTTP_PERMANENT_REDIRECT     = 301;   /*  Moved permanently.       */
exports.HTTP_FOUND                  = 302;   /*  Found.                   */
exports.HTTP_SEE_OTHER              = 303;   /*  See other.               */
exports.HTTP_NOT_MODIFIED           = 304;   /*  Content not modified.    */
exports.HTTP_USE_PROXY              = 305;   /*  Must use proxy.          */
exports.HTTP_306_UNUSED             = 306;   /*  Unused.                  */
exports.HTTP_TEMPORARY_REDIRECT     = 307;   /*  Temporary redirect.      */
exports.HTTP_BAD_REQUEST            = 400;   /*  Malformed request.       */
exports.HTTP_UNAUTHORIZED           = 401;   /*  Requires user auth.      */
exports.HTTP_PAYMENT_REQUIRED       = 402;   /*  Payment required.        */
exports.HTTP_FORBIDDEN              = 403;   /*  Forbidden.               */
exports.HTTP_METHOD_NOT_ALLOWED     = 405;   /*  Method not allowed.      */
exports.HTTP_NOT_ACCEPTABLE         = 406;   /*  Not client acceptable.   */
exports.HTTP_PROXY_AUTH_REQUIRED    = 407;   /*  Proxy Auth required.     */
exports.HTTP_REQUEST_TIMEOUT        = 408;   /*  Request timeout.         */
exports.HTTP_CONFLICT               = 409;   /*  Conflict current state.  */
exports.HTTP_GONE                   = 410;   /*  No longer available.     */
exports.HTTP_LENGTH_REQUIRED        = 411;   /*  Need Content-Length.     */
exports.HTTP_PRECONDITION_FAILED    = 412;   /*  Precondition failed.     */
exports.HTTP_REQUEST_TOO_LARGE      = 413;   /*  Request was too large.   */
exports.HTTP_REQUEST_URI_TOO_LONG   = 414;   /*  Request URI too long.    */
exports.HTTP_UNSUPPORTED_MEDIA_TYPE = 415;   /*  Unsupported media type.  */
exports.HTTP_REQUEST_RANGE_ISSUE    = 416;   /*  Range not satisfiable.   */
exports.HTTP_EXPECTATION_FAILED     = 417;   /*  Expectation failed.      */
exports.HTTP_INTERNAL_ERROR         = 500;   /*  Internal server error.   */
exports.HTTP_NOT_IMPLEMENTED        = 501;   /*  Not implemented.         */
exports.HTTP_BAD_GATEWAY            = 502;   /*  Bad gateway.             */
exports.HTTP_SERVICE_UNAVAILABLE    = 503;   /*  Service unavailable.     */
exports.HTTP_GATEWAY_TIMEOUT        = 504;   /*  Gateway timeout.         */
exports.HTTP_UNSUPPORTED_VERSION    = 505;   /*  Version not supported.   */


/*  WebSocket status codes.  */
exports.WS_NORMAL_CLOSURE        = 1000;  /*  Normal closure.          */
exports.WS_ENDPOINT_GOING_AWAY   = 1001;  /*  Endpoint "going away".   */
exports.WS_PROTOCOL_ERROR        = 1002;  /*  Endpoint closing due to  */
                                          /*  a protocol error.        */
exports.WS_UNACCEPTABLE_DATA     = 1003;  /*  Endpoint closing due to  */
                                          /*  invalid type of data.    */
exports.WS_RESERVED_1004         = 1004;  /*  Reserved error code.     */
exports.WS_RESERVED_1005         = 1005;  /*  Reserved error code.     */
exports.WS_RESERVED_1006         = 1006;  /*  Reserved error code.     */
exports.WS_INVALID_DATA          = 1007;  /*  Endpoint closing due to  */
                                          /*  inconsistent data.       */
exports.WS_TERMINATE_CONNECTION  = 1008;  /*  Termination due to       */
                                          /*  policy violation.        */
exports.WS_MESSAGE_TOO_BIG       = 1009;  /*  Message was too big.     */
exports.WS_EXT_HANDSHAKE_MISSING = 1011;  /*  Extension negotiation    */
                                          /*  failed.                  */
exports.WS_UNEXPECTED_CONDITION  = 1011;  /*  Unxpected/Internal err.  */


/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */



/**
 *  EOF
 */
