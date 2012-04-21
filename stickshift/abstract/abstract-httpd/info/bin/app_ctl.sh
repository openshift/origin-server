#!/bin/bash -e

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

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

CART_CONF_DIR=${CARTRIDGE_BASE_PATH}/${OPENSHIFT_GEAR_TYPE}/info/configuration/etc/conf

case "$1" in
    start)
        _state=`get_app_state`
        if [ -f ${OPENSHIFT_GEAR_DIR}run/stop_lock -o idle = "$_state" ]; then
            echo "Application is explicitly stopped!  Use 'rhc app start -a ${OPENSHIFT_GEAR_NAME}' to start back up." 1>&2
            exit 0
        else
            set_app_state started
            /usr/sbin/httpd -C "Include ${OPENSHIFT_GEAR_DIR}conf.d/*.conf" -f $CART_CONF_DIR/httpd_nolog.conf -k $1
        fi
    ;;
    graceful-stop|stop)
        app_ctl_stop.sh $1
    ;;
    restart|graceful)
        set_app_state started
        /usr/sbin/httpd -C "Include ${OPENSHIFT_GEAR_DIR}conf.d/*.conf" -f $CART_CONF_DIR/httpd_nolog.conf -k $1
    ;;
esac
