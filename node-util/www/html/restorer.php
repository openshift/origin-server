<?php

list($blank, $uuid, $blank) = split("/", $_SERVER["PATH_INFO"]);
shell_exec("/usr/sbin/oo-restorer-wrapper.sh $uuid");

sleep(2);
$url=str_replace("/$uuid", "", $_SERVER["PATH_INFO"]);
header("Location: $url");

?>
