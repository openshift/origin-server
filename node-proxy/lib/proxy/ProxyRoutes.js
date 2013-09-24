var path   = require('path');
var fs     = require('fs');
var Logger = require('../logger/Logger.js');

/*!  {{{  section:  'Private-Variables'                                  */

var _default_limits = { connections: 5, bandwidth: 100 };

/*!
 *  }}}  //  End of section  Private-Variables.
 *  ---------------------------------------------------------------------
 */


/*!  {{{  section: 'Internal-Functions'                                  */

/**
 *  Loads routes from the specified file (JSON format).
 *
 *  Examples:
 *    var rj = '/var/lib/openshift/.httpd.d/$uuid_$ns_$app/route.json';
 *    _load_routes(rj);
 *
 *  @param   {String}  routing file (JSON format).
 *  @return  {Dict}    loaded routing table.
 *  @api     private
 */
function _load_routes(f) {
  if (f) {
    try {
      require.cache[f]  &&  delete require.cache[f];
      return require(f);

    } catch(err) {
      Logger.error("Failed to load routes from file '" + f + ' - ' + err);
    }
  }

  return { };

}  /*  End of function  _load_routes.  */


/**
 *  Converts an URI into a routing key.
 *
 *  Examples:
 *    _get_routing_key('OpenShift-NameSpace.rhcloud.com/app/route');
 *       // => 'openshift-namespace.rhcloud.com/app/route'
 *
 *  @param   {String}  uri for the route.
 *  @return  {String}  a routing key - used for matching incoming requests.
 *  @api     private
 */
function _get_routing_key(uri) {
  if ('undefined' === typeof uri) {
    return uri;
  }

  Logger.debug(uri);

  /*  Trim leading spaces and split uri on '/'.  */
  var zuri   = uri.replace(/^\s+/g, '');
  var zparts = zuri.split('/');

  /*  Check if we need to strip of the scheme http[s]://  */
  if (0 == zuri.indexOf('http://')  || 0 == zuri.indexOf('https://')) {
    zparts = zuri.split('://')[1].split('/');
  }

  var zhost = zparts[0].toLowerCase();
  var zuri  = zparts.splice(1).join('/');

  return((zuri.length > 0)? [zhost, zuri].join('/') : zhost);

}  /*  End of function  _get_routing_key.  */


/*!
 *  }}}  //  End of section  Internal-Functions.
 *  ---------------------------------------------------------------------
 */


/*!  {{{  section:  'Exported-Functions'                                 */

/**
 *  Constructs a new ProxyRoutes instance.
 *
 *  Examples:
 *    var rtab = new ProxyRoutes.ProxyRoutes();
 *
 *  @return  {ProxyRoutes}  new ProxyRoutes instance.
 *  @api     public
 */
function ProxyRoutes() {
  this.routes = { };
  return this;

}  /*  End of function  ProxyRouter (constructor).  */


/*!
 *  }}}  //  End of section  Exported-Functions.
 *  ---------------------------------------------------------------------
 */



/*!  {{{  section:  'External-API-Functions'                             */

/**
 *  Clears all the routes.
 *
 *  Examples:
 *    var rj   = '/var/lib/openshift/.httpd.d/$uuid_$ns_$app/route.json';
 *    var rtab = new ProxyRoutes.ProxyRoutes();
 *    rtab.load(rj);
 *    rtab.clear();
 *
 *  @api  public
 */
ProxyRoutes.prototype.clear = function() {
  this.routes = { };

};  /*  End of function  clear.  */


/**
 *  Adds a route for the specified 'name' (port/virtual host/alias).
 *
 *  Examples:
 *    var rtab = new ProxyRoutes.ProxyRoutes();
 *    rtab.add('app1-ramr.rhcloud.com', '127.5.1.1:8080');
 *    rtab.add('app2-ramr.rhcloud.com',
 *             [ '127.5.1.1:8080', '10.1.1.1:37540'],
 *             { 'connections': 20 }
 *            );
 *    rtab.add(37373, [ '127.5.1.1:3306' ], { 'connections': 3 }, '528603231ae84681858491fb5e50739f');
 *
 *
 *  @param   {Integer|String}  External route name/info (external port or
 *                             virtual host/alias name).
 *  @param   {String|Array}    Single endpoint or an array of endpoints.
 *  @param   {Dict}            Usage limits.
 *  @param   {String}          Container UUID, if idled.
 *  @return  {Dict}            The replaced route (if any).
 *  @api     public
 */
ProxyRoutes.prototype.add = function(n, endpts, limits, container_uuid) {
  /*  Scrub parameters and add the specified route.  */
  if (!n) {
    return { };
  }

  limits  ||  (limits = _default_limits);
  endpts  ||  (endpts = [ ]);
  if (('string' === typeof endpts)  ||  ('number' === typeof endpts)) {
    endpts = [ endpts ];
  }
  container_uuid || (container_uuid = "");

  /*  Convert name to routing key.  */
  var rkey = _get_routing_key(n);

  /*  Add the route.  */
  this.routes[rkey] = { 'endpoints': endpts, 'limits': limits, 'idle': container_uuid };

  // Logger.debug("ProxyRoutes.add '" + n + "' => " + endpts);
  // Logger.debug("ProxyRoutes.add '" + n + "' limits => " + JSON.stringify(limits));

  return this.routes[rkey];

};  /*  End of function  add.  */


/**
 *  Removes a route for the specified 'name' (port/virtual host/alias).
 *
 *  Examples:
 *    var rj   = '/var/lib/openshift/.httpd.d/$uuid_$ns_$app/route.json';
 *    var rtab = new ProxyRoutes.ProxyRoutes();
 *    rtab.load(rj);
 *    rtab.remove('appy-ramr.rhcloud.com');
 *
 *  @param   {Integer|String}  External route name/info (external port or
 *                             virtual host/alias name).
 *  @return  {Dict}            The removed route (if any).
 *  @api     public
 */
ProxyRoutes.prototype.remove = function(n) {
  if (!n  ||  !this.routes[n]) {
    return { };
  }

  var zroute = this.routes[n];
  delete this.routes[n];

  // Logger.debug('ProxyRoutes.remove - ' + JSON.stringify(zroute));

  return zroute;

};  /*  End of function  remove.  */


/**
 *  Loads routes from the specified file (JSON format).
 *  The routes file should contain entries of the form:
 *  {
 *    <route-to>: {'endpoints': [ <list> ], 'limits': { <dict> }, 'idle': 'container_uuid'},
 *    <route-66>: {'endpoints': [ <list> ], 'limits': { <dict> }, 'idle': ''},
 *    <route-80>: {'endpoints': [ <list> ] }
 *  }
 *
 *  Examples:
 *    var rj   = '/var/lib/openshift/.httpd.d/$uuid_$ns_$app/route.json';
 *    var rtab = new ProxyRoutes.ProxyRoutes();
 *    rtab.load(rj);
 *
 *  Note:
 *    If the 'idle' element is missing or empty the application is assumed to be running
 *
 *  @param  {String}  JSON format file containing routing information.
 *  @api    public
 */
ProxyRoutes.prototype.load = function(f) {
  Logger.debug("Loading routes from file '" + f + "'. ");
  var zroutes = _load_routes(f);
  for (var d in zroutes) {
    this.add(d, zroutes[d].endpoints, zroutes[d].limits, zroutes[d].idle);
  }

  Logger.debug("Loaded routes from file '" + f + "'. ");

};  /*  End of function  load.  */


/**
 *  Gets the routes (endpoints) associated with the specified 'name'
 *  (port/virtual host/alias).
 *
 *  Examples:
 *    var rj   = '/var/lib/openshift/.httpd.d/$uuid_$ns_$app/route.json';
 *    var rtab = new ProxyRoutes.ProxyRoutes();
 *    rtab.load(rj);
 *    rtab.get('app1-ramr.rhcloud.com');
 *    rtab.get(35753);
 *
 *
 *  @param   {Integer|String}  External route name/info (external port or
 *                             virtual host/alias name).
 *  @return  {Array}           Associated endpoints/routes.
 *  @api     public
 */
ProxyRoutes.prototype.get = function(n) {
  var rkey = _get_routing_key(n);
  return((rkey && this.routes[rkey])? this.routes[rkey].endpoints : [ ]);

};  /*  End of function  get.  */


/**
 *  Get the limits associated with specified 'name' (port/vhost/alias).
 *
 *  Examples:
 *    var rj   = '/var/lib/openshift/.httpd.d/$uuid_$ns_$app/route.json';
 *    var rtab = new ProxyRoutes.ProxyRoutes();
 *    rtab.load(rj);
 *    rtab.getLimits('app1-ramr.rhcloud.com');
 *
 *
 *  @param   {Integer|String}  External route name/info (external port or
 *                             virtual host/alias name).
 *  @return  {Dict}            Associated limits.
 *  @api     public
 */
ProxyRoutes.prototype.getLimits = function(n) {
  if (n  &&  this.routes[n])
     return this.routes[n].limits;

  return _default_limits;

};  /*  End of function  getLimits.  */


/**
 *  Get the idled container UUID associated with specified 'name' (port/vhost/alias).
 *
 *  Examples:
 *    var rj   = '/var/lib/openshift/.httpd.d/$uuid_$ns_$app/route.json';
 *    var rtab = new ProxyRoutes.ProxyRoutes();
 *    rtab.load(rj);
 *    rtab.getIdle('app1-ramr.rhcloud.com');
 *
 *
 *  @param   {Integer|String}  External route name/info (external port or
 *                             virtual host/alias name).
 *  @return  {String}          Container UUID, if idled. Otherwise, ""
 *  @api     public
 */
ProxyRoutes.prototype.getIdle = function(n) {
  var rkey = _get_routing_key(n);
  if (rkey  &&  this.routes[rkey])
        return this.routes[rkey].idle;

    return "";

};  /*  End of function  getIdle.  */

/**
 *  Unidle container UUID associated with specified 'name' (port/vhost/alias).
 *
 *  Examples:
 *    var rj   = '/var/lib/openshift/.httpd.d/$uuid_$ns_$app/route.json';
 *    var rtab = new ProxyRoutes.ProxyRoutes();
 *    rtab.load(rj);
 *    rtab.unidle('app1-ramr.rhcloud.com');
 *
 *  Note: this does not update the disk version of the file.
 *
 *  @param   {Integer|String}  External route name/info (external port or
 *                             virtual host/alias name).
 *  @api     public
 */
ProxyRoutes.prototype.unIdle = function (n) {
  var rkey = _get_routing_key(n);
  if (rkey && this.routes[rkey]) {
    var uuid = this.routes[rkey].idle
    this.routes[rkey].idle = "";
    return uuid;
  }

  return "";
};  /*  End of function  getIdle.  */

/**
 *  Get the max connections limit associated with the specified 'name'
 *  (port/virtual host/alias).
 *
 *  Examples:
 *    var rj   = '/var/lib/openshift/.httpd.d/$uuid_$ns_$app/route.json';
 *    var rtab = new ProxyRoutes.ProxyRoutes();
 *    rtab.load(rj);
 *    rtab.getConnectionLimit('app1-ramr.rhcloud.com');
 *
 *
 *  @param   {Integer|String}  External route name/info (external port or
 *                             virtual host/alias name).
 *  @return  {Integer}         Associated connection limit.
 *  @api     public
 */
ProxyRoutes.prototype.getConnectionLimit = function(n) {
  return this.get(n).connections;

};  /*  End of function  getConnectionLimit.  */


/**
 *  Get the bandwidth limits associated with the specified 'name'
 *  (port/virtual host/alias).
 *
 *  Examples:
 *    var rj   = '/var/lib/openshift/.httpd.d/$uuid_$ns_$app/route.json';
 *    var rtab = new ProxyRoutes.ProxyRoutes();
 *    rtab.load(rj);
 *    rtab.getBandwidthLimits('app1-ramr.rhcloud.com');
 *
 *
 *  @param   {Integer|String}  External route name/info (external port or
 *                             virtual host/alias name).
 *  @return  {Dict}            Associated bandwidth limits.
 *  @api     public
 */
ProxyRoutes.prototype.getBandwidthLimits = function(n) {
  return this.get(n).bandwidth;

};  /*  End of function  getBandwidthLimits.  */


/*!
 *  }}}  //  End of section  External-API-Functions.
 *  ---------------------------------------------------------------------
 */



/*!  {{{  section: 'Module-Exports'                                      */

exports.ProxyRoutes = ProxyRoutes;

/*!
 *  }}}  //  End of section  Module-Exports.
 *  ---------------------------------------------------------------------
 */



/**
 *  EOF
 */
