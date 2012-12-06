var fs  = require('fs');


/*!  {{{  section: 'Module-Exports'                                      */

/**
 *  Returns the current working directory.
 *
 *  Examples:
 *    Utils.cwd();
 *
 *  @api  public
 */
exports.cwd = function() {
  return ((typeof(__dirname) === 'undefined') ? '.' : __dirname);

};  /*  End of function  cwd.  */


/**
 *  Returns whether or not a variable is defined.
 *
 *  Examples:
 *    Utils.isDefined(myvar);
 *
 *  @param  {v}  the variable.
 *  @api    public
 */
exports.isDefined = function(v) {
   return('undefined' !== typeof(v) );

};  /*  End of function  isDefined.  */



/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */



/**
 *  EOF
 */
