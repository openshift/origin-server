#!/bin/bash

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/apache

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

CART_CONF_DIR=${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/configuration/etc/conf

cart_instance_dir=${OPENSHIFT_HOMEDIR}/${cartridge_type}

HTTPD_CFG_FILE=$CART_CONF_DIR/httpd_nolog.conf
HTTPD_PID_FILE=$cart_instance_dir/run/httpd.pid

# Stop the app
src_user_hook pre_stop_${cartridge_type}
set_app_state stopped
httpd_pid=`cat "$HTTPD_PID_FILE" 2> /dev/null`
ensure_valid_httpd_process "$HTTPD_PID_FILE" "$HTTPD_CFG_FILE"
/usr/sbin/httpd -C "Include ${OPENSHIFT_HOMEDIR}/${cartridge_type}/conf.d/*.conf" -f $CART_CONF_DIR/httpd_nolog.conf -k $1
wait_for_stop $httpd_pid
run_user_hook post_stop_${cartridge_type}
