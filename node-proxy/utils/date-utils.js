
/*!  {{{  section: 'Module-Exports'                                      */

/**
 *  Returns the day of week (abbreviated form if so asked) associated with
 *  the specified date or day number.
 *
 *  Examples:
 *    DateUtils.getDayOfWeek(0);                 // ==> 'Sunday'
 *    DateUtils.getDayOfWeek(new Date(), true);  // ==> 'Fri' on a Friday!!
 *
 *  @param   {Integer|Date}  Date or a day number (defaults to current day).
 *  @param   {Boolean}       true|false - return the abbreviated form.
 *  @return  {String}        Day of the week in abbreviated/full form.
 *  @api     public
 */
exports.getDayOfWeek = function(d, abbrev) {
  var days = [ 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday',
               'Friday', 'Saturday' ];

  /*  Convert defaults/Date to the day number form.  */
  d  ||  (d = new Date());
  var dn = (d instanceof Date)? d.getDay() : d;
  var idx = (dn >= 0) ? (dn%7) : ((dn%7) + 7); 

  return(abbrev ? days[idx].slice(0,3) : days[idx]);

}  /*  End of function  getDayOfWeek.  */


/**
 *  Returns the month name (abbreviated form if so asked) associated with
 *  the specified date or month number.
 *
 *  Examples:
 *    DateUtils.getMonthName(new Date() );  // ==> 'January' in january!
 *    DateUtils.getMonthName(3, true);      // ==> 'April'
 *
 *  @param   {Integer|Date}  Date object or a month number (defaults to
 *                           current month).
 *  @param   {Boolean}       true|false - return the abbreviated form.
 *  @return  {String}        Month in abbreviated/full form.
 *  @api     public
 */
exports.getMonthName = function(m, abbrev) {
  var months = [ 'January', 'February', 'March', 'April', 'May', 'June',
                 'July', 'August', 'September', 'October', 'November',
                 'December' ];

  /*  Convert defaults/Date to the month number form.  */
  m  ||  (m = new Date());
  var mn = (m instanceof Date)? m.getMonth() : m;
  var idx = (mn >= 0) ? (mn%12) : ((mn%12) + 12); 

  return(abbrev ? months[idx].slice(0,3) : months[idx]);

};  /*  End of function  getMonthName.  */


/**
 *  Returns the day of the year associated with the specified Date.
 *
 *  Examples:
 *    DateUtils.getDayOfYear(new Date() );
 *
 *  @return  {Integer}  Day number of the year (defaults to current date).
 *  @api     public
 */
exports.getDayOfYear = function(d) {
  var monthdays = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];
  var ndays = 0;

  /*  Use current date and time if not passed.  */
  d  ||  (d = new Date());

  var mon  = d.getMonth();
  var day  = d.getDate();
  var year = d.getFullYear();

  monthdays.slice(0, mon).forEach(function(d) { ndays += d; });
  var leapday = 0;
  if ((0 == year%4) && ((0 != year%100) || (0 == year%400)) && (mon > 1)) {
    /*  Note: mon is 0 indexed - 0 is Jan and so 2 is March.  */
    leapday = 1;
  }

  return(ndays + day + leapday);

};  /*  End of function  getDayOfYear.  */


/**
 *  Format date and time ala strftime.
 *
 *  Examples:
 *    DateUtils.strftime('%a', new Date() );
 *
 *  @param   {String}  Date and Time format string - man strftime
 *  @param   {Date}    Given date (defaults to current date and time).
 *  @return  {String}  Formatted date and time as per the format string.
 *  @api     public
 */
exports.strftime = function(fmt, d) {
  /*  Use current date and time if not passed.  */
  d  ||  (d = new Date());

  var self = this;
  return fmt.replace(/%([aAbBcCdDeFGghHIjklmMnpPrRsStTuUVwWxXyYzZ\+%]|E[cCxXyY]|O[deHImMSuUVwWy])/g, function(m) {
    switch(m) {
      case '%a': return self.getDayOfWeek(d.getDay(), true);
      case '%A': return self.getDayOfWeek(d.getDay() );
      case '%b': return self.getMonthName(d.getMonth(), true);
      case '%B': return self.getMonthName(d.getMonth() );
      case '%c': return Date(d);
      case '%C': return parseInt(d.getFullYear()/100);
      case '%d': return ('0' + d.getDate()).slice(-2);
      case '%D': return self.strftime('%m/%d/%y', d);
      case '%e': return (' ' + d.getDate()).slice(-2);
      case '%F': return self.strftime('%Y-%m-%d', d);
      case '%G': return self.strftime('%C', d);
      case '%g': return self.strftime('%c', d);
      case '%h': return self.strftime('%b', d);
      case '%H': return ('0' + d.getHours()).slice(-2);
      case '%I': hr = d.getHours()%12;
                 return((hr > 0)? hr : 12);
      case '%j': return self.getDayOfYear(d);
      case '%k': return self.strftime('%H', d);
      case '%l': hr = d.getHours()%12; hr = hr > 0 ? hr : 12;
                 return (' ' + hr).slice(-2);
      case '%m': return (1 + d.getMonth());
      case '%M': return ('0' + d.getMinutes()).slice(-2);
      case '%n': return '\n';
      case '%p': return (d.getHours() < 12 ? 'AM' : 'PM');
      case '%P': return (d.getHours() < 12 ? 'am' : 'pm');
      case '%r': return self.strftime('%I:%M:%S %p', d);
      case '%R': return self.strftime('%H:%M', d);
      case '%s': return d.valueOf();
      case '%S': return ('0' + d.getSeconds()).slice(-2);
      case '%t': return '\t';
      case '%T': return self.strftime('%H:%M:%S', d);
      case '%u': day = d.getDay()%7;
                 return((day > 0)? day : 7);
      case '%w': return d.getDay();
      case '%x': return d.toLocaleDateString();
      case '%X': return d.toLocaleTimeString();
      case '%y': return (d.getYear() % 100);
      case '%Y': return d.getFullYear();
      case '%z': return d.getTimezoneOffset();
      case '%Z': return d.toString().slice(-5).slice(1,4);
      case '%+': return self.strftime('%a %b %d %H:%M:%S %Z %Y', d);
      case '%%': return self.strftime('%', d);
      case '%Ec': return self.strftime('%c', d);
      case '%EC': return self.strftime('%C', d);
      case '%Ex': return self.strftime('%x', d);
      case '%EX': return self.strftime('%X', d);
      case '%Ey': return self.strftime('%y', d);
      case '%EY': return self.strftime('%Y', d);
      case '%Od': return self.strftime('%d', d);
      case '%Oe': return self.strftime('%e', d);
      case '%OH': return self.strftime('%H', d);
      case '%OI': return self.strftime('%I', d);
      case '%Om': return self.strftime('%m', d);
      case '%OM': return self.strftime('%M', d);
      case '%OS': return self.strftime('%S', d);
      case '%Ou': return self.strftime('%u', d);
      case '%OU': return self.strftime('%U', d);
      case '%OV': return self.strftime('%V', d);
      case '%Ow': return self.strftime('%w', d);
      case '%OW': return self.strftime('%W', d);
      case '%Oy': return self.strftime('%y', d);

      /*  TODO:  To do add support for %U, %V and %W.  */

/**
 *    case '%U': return 999;
 *    %U  The week number of the current year as a decimal number,
 *        range 00 to 53, starting with the first Sunday as the first day
 *        of week 01. See also %V and %W.
 *
 *    case '%V': return 999; 
 *    %V  The ISO 8601 week number (see NOTES) of the current year as a
 *        decimal number, range 01 to 53, where week 1 is the first week
 *        that has at least 4 days in the new year. See also %U and %W.
 *
 *    case '%W': return 99; // TODO
 *     %W  The week number of the current year as a decimal number,
 *         range 00 to 53, starting with the first Monday as the first day
 *         of week 01.  
 *
 */

    }  /*  End of switch  statement.  */
  });

};  /*  End of function  strftime.  */



/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */



/**
 *  EOF
 */
