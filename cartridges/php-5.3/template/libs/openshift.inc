<?php

/**
 *  This file contains functions to create secure variables for use in OpenShift applications.
 *
 *  Example Usage:
 *
 *    // Load the OpenShift functions
 *    require_once(getenv('OPENSHIFT_REPO_DIR').'libs/openshift.inc');
 *
 *    // Specify default variables to regenerate
 *    $_default_keys = array(
 *      'FOO' => 'bar'
 *    );
 *
 *    // Generate OpenShift secure keys (or return defaults if not on OpenShift)
 *    $array = openshift_secure($_default_keys);
 *
 *    // Loop through returned values and define them
 *    foreach ($array as $key => $value) {
 *      define($key,$value);
 *    }
 *
 *  Can also be called with a function to format the secure keys
 *
 *    // This function gets called by openshift_secure and passes an array
 *    function make_secure_key($args) {
 *      return substr($args['hash'],0,55);
 *    }
 *
 *    $array = openshift_secure($_default_keys,'make_secure_key');
 *
 */

/**
 * Returns the secret token provided by OpenShift
 * @access private
 *
 * @return string|null Either the OPENSHIFT_SECRET_TOKEN, a pseudo-secure hash, or null
 */
function get_openshift_secret_token() {
  $my_token = null;

  $token = getenv('OPENSHIFT_SECRET_TOKEN');
  $name  = getenv('OPENSHIFT_APP_NAME');
  $uuid  = getenv('OPENSHIFT_APP_UUID');

  if ($token)
    $my_token = $token;
  elseif ($name && $uuid)
    $my_token = hash('sha256',"$name-$uuid");

  return $my_token;
}

/**
 * Formats secure variable for use
 *
 * @param array(...) $args Hash with the following format
 *            array(
 *              'hash'     => generated sha hash,
 *              'variable' => name of variable,
 *              'original' => original value
 *            )
 *
 * @return string The formatted value
 */
function default_secure_function($args){
  return $args['hash'];
}

/**
 * Loop through all provided variables and generate secure versions
 *
 * @param array(key => value,...) $default_keys The key value pairs for the default values
 * @param string|null $secure_function The function to call to format the secure value
 *
 * @return array(key => value, ...) value will be one of:
 *            - the value returned from secure_function (if it was defined)
 *            - the generated value
 *            - the original value (if not running on OpenShift)
 */
function openshift_secure($default_keys,$secure_function = null) {
  // Attempts to get secret token
  $my_token = get_openshift_secret_token();

  // If we don't pass a secure function, use the one from this example
  if(!$secure_function)
    $secure_function = 'default_secure_function';

  // Only generate random values if on OpenShift
  $array = $default_keys;

  if ($my_token){
    // Loop over each default_key and set the new value
    foreach ($default_keys as $key => $value) {
      // Create hash out of token and this key's name
      $sha = hash('sha256',"$my_token-$key");
      // Pass an array so we can add stuff without breaking existing calls
      $vals = array(
        'hash' => $sha,
        'variable'  => $key,
        'original'  => $value
      );
      // Call user specified function or default function
      $array[$key] = call_user_func($secure_function,$vals);
    }
  } else {
    // Get the relative path for a more meaningful error message
    $t = debug_backtrace();
    $calling_file = $t[0]['file'];
    // Remove directory to give relative dir for file
    if (getenv('OPENSHIFT_REPO_DIR')) {
      $base = getenv('OPENSHIFT_REPO_DIR');
      $calling_file = str_replace($base,'',$calling_file);
    }
    error_log("OPENSHIFT WARNING: Using default values for secure variables, please manually modify in $calling_file", 0);
  }
  return $array;
}

?>
