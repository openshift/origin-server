<?php

list($blank, $uuid, $blank) = split("/", $_SERVER["PATH_INFO"]);
if (preg_match('/[0-9a-fA-F]{32}/', $uuid)) {
    shell_exec("/usr/sbin/oo-restorer-wrapper.sh $uuid");
    sleep(2);
    $host = $_SERVER['HTTP_HOST'];
    $proto = "http" . ( isset($_SERVER['HTTPS']) ? 's' : '' ) . '://';
    $url=str_replace("/$uuid", "", $_SERVER["PATH_INFO"]);
    header("Location: $proto$host$url");
} else {
    // someone is trying to attack
    error_log("Invalid uuid $uuid given to restorer.php");
    header('HTTP/1.0 403 Forbidden');
}
?>
