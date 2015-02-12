<?php

list($blank, $uuid, $blank) = split("/", $_SERVER["PATH_INFO"]);
if (preg_match('/^([0-9a-fA-F]{24,32}|\w+-\w+-\d+)$/', $uuid)) {
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
