#!/bin/bash -e

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if ! [ $# -eq 1 ]
then
    echo "Usage: $0 [start|restart|graceful|graceful-stop|stop]"
    exit 1
fi

validate_run_as_user

export PHPRC="${OPENSHIFT_PHPMYADMIN_GEAR_DIR}conf/php.ini"

CART_CONF_DIR=${CARTRIDGE_BASE_PATH}/embedded/phpmyadmin-3.4/info/configuration/etc/conf

case "$1" in
    start)
        if [ -f ${OPENSHIFT_PHPMYADMIN_GEAR_DIR}run/stop_lock ]
        then
            echo "Application is explicitly stopped!  Use 'rhc app cartridge start -a ${OPENSHIFT_GEAR_NAME} -c phpmyadmin-3.4' to start back up." 1>&2
            exit 0
        else
            /usr/sbin/httpd -C "Include ${OPENSHIFT_PHPMYADMIN_GEAR_DIR}conf.d/*.conf" -f $CART_CONF_DIR/httpd_nolog.conf -k $1
        fi
    ;;

    graceful-stop|stop)
        if [ -f ${OPENSHIFT_PHPMYADMIN_GEAR_DIR}run/httpd.pid ]
        then
            httpd_pid=`cat ${OPENSHIFT_PHPMYADMIN_GEAR_DIR}run/httpd.pid 2> /dev/null`
            /usr/sbin/httpd -C "Include ${OPENSHIFT_PHPMYADMIN_GEAR_DIR}conf.d/*.conf" -f $CART_CONF_DIR/httpd_nolog.conf -k $1
            wait_for_stop $httpd_pid
        fi
    ;;

    restart|graceful)
        /usr/sbin/httpd -C "Include ${OPENSHIFT_PHPMYADMIN_GEAR_DIR}conf.d/*.conf" -f $CART_CONF_DIR/httpd_nolog.conf -k $1
    ;;
esac
