#!/bin/bash -e

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/apache

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

translate_env_vars

if ! [ $# -eq 1 ]
then
    echo "Usage: \$0 [start|restart|graceful|graceful-stop|stop]"
    exit 1
fi

validate_run_as_user

. app_ctl_pre.sh

CART_CONF_DIR=${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/configuration/etc/conf

cart_instance_dir=${OPENSHIFT_HOMEDIR}/${cartridge_type}

HTTPD_CFG_FILE=$CART_CONF_DIR/httpd_nolog.conf
HTTPD_PID_FILE=$cart_instance_dir/run/httpd.pid


case "$1" in
    start)
        _state=`get_app_state`
        if [ -f $cart_instance_dir/run/stop_lock -o idle = "$_state" ]; then
            echo "Application is explicitly stopped!  Use 'rhc app start -a ${OPENSHIFT_APP_NAME}' to start back up." 1>&2
            exit 0
        else
            ensure_valid_httpd_process "$HTTPD_PID_FILE" "$HTTPD_CFG_FILE"
            src_user_hook pre_start_${cartridge_type}
            set_app_state started
            /usr/sbin/httpd -C "Include $cart_instance_dir/conf.d/*.conf" -f $HTTPD_CFG_FILE -k $1
            run_user_hook post_start_${cartridge_type}
        fi
    ;;
    graceful-stop|stop)
        cartridge_type=$cartridge_type app_ctl_stop.sh $1
    ;;
    restart|graceful)
        ensure_valid_httpd_process "$HTTPD_PID_FILE" "$HTTPD_CFG_FILE"
        src_user_hook pre_start_${cartridge_type}
        set_app_state started
        /usr/sbin/httpd -C "Include $cart_instance_dir/conf.d/*.conf" -f $HTTPD_CFG_FILE -k $1
        run_user_hook post_start_${cartridge_type}
    ;;
esac
