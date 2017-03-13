<?php

list($blank, $uuid, $blank) = split("/", $_SERVER["PATH_INFO"]);
if (preg_match('/^([0-9a-fA-F]{24,32}|\w+-\w+-\d+)$/', $uuid)) {
    // Get the list of user agents to ignore
    $node_conf = file('/etc/openshift/node.conf');
    $useragent_ignore_list = array();
    foreach ($node_conf as $conf_line) {
      if (preg_match('/UNIDLER_IGNORE_LIST/', $conf_line)) {
        $useragent_ignore_value = array();
        preg_match('/UNIDLER_IGNORE_LIST=[\'"]*([^"\']+)[\'"]*/', $conf_line, $useragent_ignore_value);
        $useragent_ignore_list = explode(",", $useragent_ignore_value[1]);
        break;
      }
    }
    // If the user agent matches one in the list, move on.
    foreach ($useragent_ignore_list as $ignore) {
      if (preg_match("/" . $ignore . "/", $_SERVER["HTTP_USER_AGENT"])) {
        header('HTTP/1.0 403 Forbidden');
        exit;
      }
    }
    $safe_uuid = escapeshellarg($uuid);
    shell_exec("/usr/sbin/oo-restorer-wrapper.sh $safe_uuid");
    sleep(2);
    $host = $_SERVER['HTTP_HOST'];
    $proto = "http" . ( isset($_SERVER['HTTPS']) ? 's' : '' ) . '://';
    $url=str_replace("/$uuid", "", $_SERVER["PATH_INFO"]);
    header("Location: $proto$host$url");
    // Prevent the same connection from being reused - causes a redirect loop.
    header("Connection: close");
} else {
    // someone is trying to attack
    error_log("Invalid uuid $uuid given to restorer.php");
    header('HTTP/1.0 403 Forbidden');
}
?>
