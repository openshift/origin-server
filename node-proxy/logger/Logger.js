var path = require('path');
var fs   = require('fs');
var util = require('util');

/*  load in util and log constants.  */
var logconstants = require('./log-constants.js');
var dateutils    = require('../utils/date-utils.js');


/*!  {{{  section:  'Private-Variables'                                  */

var _zloggers    = { };  /*  Dictionary of loggers.  */
var _log_methods = (Object.keys(logconstants.LOG_LEVEL_SYNONYMS) +
                    ',' + logconstants.LOG_LEVELS).split(',');


/*!
 *  }}}  //  End of section  Private-Variables.
 *  ---------------------------------------------------------------------
 */


/*!  {{{  section: 'Internal-Functions'                                 */

/**
 *  Register a logger - overwrites any existing registered loggers.
 *
 *  Examples:
 *    _register('access.log', accessLogger);
 *
 *  @param   {String}  Logger name.
 *  @api     private
 */
function _register(name, logger) {
  _zloggers[name] = logger;

}  /*  End of function  _register.  */


/**
 *  Deregister a logger.
 *
 *  Examples:
 *    _deregister('access.log');
 *
 *  @param  {String}  Logger name.
 *  @api    private
 */
function _deregister(name) {
  var zlogger = _zloggers[name];
  if (zlogger  &&  zlogger.hasOwnProperty('close') ) {
    zlogger.close();
  }

  delete _zloggers[name];

}  /*  End of function  _deregister.  */


/**
 *  Map the specified log level (synonymn) to valid Logger level.
 *
 *  Examples:
 *    _mapLogLevel('ERR');  // => ERROR.
 *
 *  @param   {String}  Logging level.
 *  @return  {String}  Mapped log level.
 *  @api     private
 */
function _mapLogLevel(lvl) {
  var zdefault = logconstants.DEFAULT_LOG_LEVEL;
  var lvlname  = logconstants.LOG_LEVEL_SYNONYMS[lvl];

  var zlvl = lvlname? lvlname : lvl;

  var idx = logconstants.LOG_LEVELS.indexOf(zlvl);
  return((idx >= 0) ? logconstants.LOG_LEVELS[idx] : zdefault);

}  /*  End of function  _mapLogLevel.  */


/**
 *  Compute the expiry time based on the specified timestamp and frequency.
 *
 *  Examples:
 *     _computeExpiry(Date.now(), '2days');  // => 24219239
 *
 *  @param   {String}  Start timestamp.
 *  @param   {String}  Frequency - default is 'daily'.
 *  @return  {Number}  Expiry time in milliseconds.
 *  @api     private
 */
function _computeExpiry(ts, freq) {
  var freq_days_map = {
    'daily': 1,   '1day': 1,
    '2days': 2,  '3days': 3, '4days': 4, '5days': 5,
    '6days': 6,
    '7days': 7, 'weekly': 7
  };

  var ndays  = (freq_days_map[freq])? freq_days_map[freq] : 1;
  var expiry = new Date(ts);
  expiry.setHours(0, 0, 0, 0);
  expiry.setDate(expiry.getDate() + ndays);
  return(expiry - ts);

}  /*  End of function  _computeExpiry.  */


/*!
 *  }}}  //  End of section  Internal-Functions.
 *  ---------------------------------------------------------------------
 */



/*!  {{{  section: 'Exported-Functions'                                  */

/**
 *  Initialize loggers from the given configuration file (JSON format).
 *
 *  Examples:
 *    Logger.initialize('/etc/openshift/node-proxy/config.json');
 *
 *  @param   {String}  Configuration file path (JSON format).
 *  @return  {Array}   List of initialized loggers.
 *  @api     public
 */
var initialize = function(cj) {
  var loggers = [ ];
  if (cfg  &&  cfg.loggers) {
    for (var n in cfg.loggers) {
      /*  Remove any old loggers and recreate the logger. */
      var l = getLogger(n);
      l.destroy();
      loggers.push(new Logger(n, cfg.loggers[n]) );
    }
  }

  return loggers;

};  /*  End of function  initialize.  */


/**
 *  Return a logger by name - creates a new instance if one is not found.
 *
 *  Examples:
 *    Logger.initialize('/etc/openshift/node-proxy/config.json');
 *    Logger.get('access.log');
 *
 *  @param   {String}  Logger name.
 *  @return  {Logger}  Logger instance.
 *  @api     public
 */
var getLogger = function(n) {
  /*  Scrub parameters.  */
  n  ||  (n = 'default');

  /*  Check if we have a matching logger - if not create a new one.  */
  var zlogger = _zloggers[n];
  return(zlogger? zlogger : new Logger(n) );

};  /*  End of function  getLogger.  */


/**
 *  Constructs a new logger instance.
 *
 *  Examples:
 *    new Logger.Logger('error.log', '/var/log/node-ws-proxy/error.log');
 *    new Logger.Logger('error.log',
 *                      {'file'    : '/var/log/error.log',
 *                       'rollover': { 'max-size-bytes': 10485760 }
 *                     );
 *
 *  @param   {String}       Logger name.
 *  @param   {String|Dict}  Log file path or configuration.
 *  @return  {Logger}       Logger instance.
 *  @api     public
 */
var Logger = function(name, path_or_cfg) {
  this.tag       = name;
  this.log_level = logconstants.DEFAULT_LOG_LEVEL;
  this._stream   = undefined;
  this._open_ts  = 0;

  if (path_or_cfg) {
    if ('string' === typeof path_or_cfg) {
      this.logfile = path_or_cfg;
    }
    else {
      this.logfile  = path_or_cfg.file;
      this.rollover = path_or_cfg.rollover;
    }
  }

  this.rollover  ||  (this.rollover = { });

  this._buffered_logs = '';

  /*  Also open/initialize the logger streams.  */
  this.open();

  /*  And finally register this logger.  */
  _register(name, this);

  return this; 

};  /*  End of function  Logger (constructor).  */


/*!
 *  }}}  //  End of section  Exported-Functions.
 *  ---------------------------------------------------------------------
 */



/*!  {{{  section:  'External-API-Functions'                             */

/**
 *  Initializes (opens) a new logger instance.
 *
 *  Examples:
 *    var errlog = Logger.get('error.log');
 *    errlog.open();
 *
 *  @return  {boolean}  true or false depending on whether there is an
 *                      associated stream and if it was opened.
 *  @api     public
 */
Logger.prototype.open = function() {
  if (!this.logfile) {
    return false;
  }

  if (this._stream) {
    return true;
  }

  var logdir = path.dirname(this.logfile);
  if (path.existsSync(logdir) ) {
    this._stream = fs.createWriteStream(this.logfile, {'flags': 'wt'});
    this._stream.once('open', function(fd) {
      this._open_ts = Date.now();
      this._stream.write('# Log opened @ ' + Date(this._open_ts) + '\n');

      /*  Compute rollover time and set a timeout to do the rollover.  */
      var expiry = _computeExpiry(this._open_ts, this.rollover.frequency);
      this._timeoutId = setTimeout(this.rollover, expiry);
    });
  }
  else {
    console.log("ERROR: Could not open logfile '" + this.logfile +
                "', log dir does not exist - using stderr ...");
  }

  return true;

};  /*  End of function  open.  */


/**
 *  Closes any stream associated with this logger instance.
 *
 *  Examples:
 *    var errlog = Logger.get('error.log');
 *    errlog.close();
 *
 *  @api  public
 */
Logger.prototype.close = function() { 
  if (this._buffered_logs.length > 0) {
    if (this._stream) {
      this._stream.write(this._buffered_logs);
    }
    else {
      console.log(this._buffered_logs);
    }

    this._buffered_logs = '';
  }

  if (this._timeoutId) {
    clearTimeout(this._timeoutId);
    this._timeoutId = undefined;
  }

  if (this._stream) {
     this._stream.destroy();
  }

  this._stream  = undefined;
  this._open_ts = 0;

};  /*  End of function  close.  */


/**
 *  Rolls over the previously opened log file.
 *
 *  Examples:
 *    var errlog = Logger.get('error.log');
 *    errlog.rollover();
 *
 *  @api  public
 */
Logger.prototype.rollover = function() {
  var suffix = this.rollover.suffix ? this.rollover.suffix : '%F';

  if (this._stream) {
    var tdiff = new Date(Date.now()) - new Date(this._open_ts);
    var tdiffInHours = tdiff/(60*60*1000);
    if (tdiffInHours > 1) {
      /*  Coalesce rollovers within 1 hour of each other.  */
      this.close();
      var ro_file = this.logfile + '.' +
                    dateutils.strftime(suffix, this._open_ts);
      fs.renameSync(this.logfile, ro_file);
      this.open();
    }
  }

};  /*  End of function  rollover.  */


/**
 *  Destroys and deregisters this logger instance.
 *
 *  Examples:
 *    var errlog = Logger.get('error.log');
 *    errlog.destroy();
 *
 *  @api  public
 */
Logger.prototype.destroy = function() { 
  this.close();
  _deregister(this.name);
  delete this;

};  /*  End of function  destroy.  */


/**
 *  Set the default logging level.
 *
 *  Examples:
 *    var customlog = Logger.get('custom.log');
 *    customlog.setLevel('INFO');
 *
 *  @param  {String}  Logging level.
 *  @api    public
 */
Logger.prototype.setLevel = function(lvl) {
  this.log_level = _mapLogLevel(lvl);

};  /*  End of function  setLevel.  */


/**
 *  Set the log format.
 *
 *  Examples:
 *    var customlog = Logger.get('custom.log');
 *    customlog.setFormat('TBD');
 *
 *  @param  {String}  Logging format.
 *  @api    public
 */
Logger.prototype.setFormat = function(fmt) {
  /*  TODO: Add log format support.  */
  this._format = 'unused-for-now'

};  /*  End of function  setFormat.  */


/**
 *  Logs a message at the specified logging level.
 *
 *  Examples:
 *    var mylog = Logger.get('mylog.log');
 *    mylog.logMessage('Epic failure!', 'ERR');
 *
 *  @param  {String}  message to be logged.
 *  @param  {String}  logging level.
 *  @api    public
 */
Logger.prototype.logMessage = function(msg, lvl) {
  var zlvl = _mapLogLevel(lvl);
  var zidx = logconstants.LOG_LEVELS.indexOf(zlvl);

  if (zidx > logconstants.LOG_LEVELS.indexOf(this.log_level) ) {
     return;
  }
  
  var ts = Date.now();

  /*  TODO: To do - use this._format to generate the log message.  */
  var zmsg = ts + ':' + lvl + ':[' + Date(ts) + '] - ' + msg;
  if (this._stream) {
    /*  TODO: handle kernel buffering and drain events.  */
    return this._stream.write(zmsg);
  }

  return console.log(zmsg);

};  /*  End of function  logMessage.  */


/**
 *  Generate functions for all the log methods.
 *  This will generate functions for the Logger prototype which can be
 *  invoked as: 
 *    Logger.emergency, Logger.alert, Logger.critical, Logger.error,
 *    Logger.warn, Logger.warning, Logger.notice, Logger.info,
 *    Logger.debug, Logger.trace
 */
_log_methods.forEach(function(m) {

  /**
   *  Logs a message at the specified 'm' log level.
   *
   *  Examples:
   *    var clog = Logger.get('custom.log');
   *    clog.trace('Who's on first!');
   *    clog.debug('Look %s, no hands!', 'ma');
   *    clog.informational('Technically bananas are herbs');
   *    clog.inform('Karaoke is a %s and means "%s" in Japanese',
   *                'portmanteau of kara and ōkesutora', 'empty orchestra');
   *    clog.info('The first use of the word "nerd" is by %s in "%s",
   *              'Dr. Seuss', 'If I Ran the Zoo');
   *    clog.notice('SF Giants - the comeback kids!');
   *    clog.notice('SF Giants - the comeback kids!');
   *    clog.warning('Warning Signs - Coldplay');
   *    clog.warn('No more Mr. Nice Guy');
   *    clog.error('What's on second!');
   *    clog.err('To err is human ... ');
   *    clog.critical('Got milk?');
   *    clog.crit('%s 15 minutes of battery life remaining',
   *              'Running on empty ...');
   *    clog.alert('Low disk space - free space at %d%', 7);
   *    clog.emergency('CPU fan failure, system will shutdown now');
   *    clog.emerg('No more disk space remaining');
   *
   *  @param  {arguments}  message to log at the specified log level
   *                       using C style printf like arguments.
   *  @api    public
   */
  Logger.prototype[m.toLowerCase() ] = function() {
    return this.logMessage(util.format.apply(null, arguments),
                           m.toUpperCase() );

  };  /*  End of function Logger[m].  */

});


/*!
 *  }}}  //  End of section  External-API-Functions.
 *  ---------------------------------------------------------------------
 */



/*!  {{{  section: 'Module-Exports'                                      */

exports.initialize = initialize;
exports.get        = getLogger;
exports.Logger     = Logger;

/**
 *  Export all the log methods mapped to the default logger functions.
 *  This will generate exported functions: 
 *    exports.emergency, exports.emerg, exports.alert,
 *    exports.critical, exports.crit, exports.error, exports.err,
 *    exports.warning, exports.warn, exports.notice,
 *    exports.informational, exports.inform, exports.info,
 *    exports.debug, exports.trace
 */
_log_methods.forEach(function(m) {
  var fname = m.toLowerCase();
  exports[fname] = function() {
    getLogger()[fname](util.format.apply(null, arguments) );
  };
});


/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */


/**
 *  EOF
 */
