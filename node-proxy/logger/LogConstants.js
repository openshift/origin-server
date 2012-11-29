
/*  {{{  section: "Module-Exports"                                       */

exports.MAX_LOG_CACHE_LIMIT = 4096;    /*  Max log msg cache limit.  */
exports.DEFAULT_LOG_LEVEL   = "INFO";  /*  Default log level.        */

/*  Logging levels.  */
exports.LOG_LEVELS = [ "EMERG", "ALERT", "CRIT", "ERROR", "WARNING",
                       "NOTICE", "INFO", "DEBUG", "TRACE"
                     ];

/*  Logging level synonyms.  */
exports.LOG_LEVEL_SYNONYMS = {
  "EMERGENCY":     "EMERG", 
  "CRITICAL":      "CRIT",
  "ERR":           "ERROR",
  "WARN":          "WARNING",
  "INFORMATIONAL": "INFO",
  "INFORM":        "INFO"
};


/**
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */


/**
 *  EOF
 */
