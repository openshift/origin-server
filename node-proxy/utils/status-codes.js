
/*!  {{{  section: 'Module-Exports'                                      */

/*  Temporary Redirect and Service Unavailable HTTP codes.  */ 
exports.HTTP_TEMPORARY_REDIRECT  = 302;   /*  Temporary redirect.      */
exports.HTTP_SERVICE_UNAVAILABLE = 503;   /*  Service is unavailable.  */


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
