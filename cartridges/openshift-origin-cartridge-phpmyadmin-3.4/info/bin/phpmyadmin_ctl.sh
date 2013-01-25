#!/bin/bash -e

cartridge_type="phpmyadmin-3.4"

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/apache


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

PHPMYADMIN_DIR="$OPENSHIFT_HOMEDIR/$cartridge_type/"

export PHPRC="${PHPMYADMIN_DIR}conf/php.ini"

CART_CONF_DIR=${CARTRIDGE_BASE_PATH}/embedded/${cartridge_type}/info/configuration/etc/conf
HTTPD_CFG_FILE=$CART_CONF_DIR/httpd_nolog.conf
HTTPD_PID_FILE=${PHPMYADMIN_DIR}run/httpd.pid

case "$1" in
    start)
        if [ -f ${PHPMYADMIN_DIR}run/stop_lock ]
        then
            echo "Application is explicitly stopped!  Use 'rhc cartridge start -a ${OPENSHIFT_APP_NAME} -c ${cartridge_type}' to start back up." 1>&2
            exit 0
        else
            ensure_valid_httpd_process "$HTTPD_PID_FILE" "$HTTPD_CFG_FILE"
            src_user_hook pre_start_${cartridge_type}
            /usr/sbin/httpd -C "Include ${PHPMYADMIN_DIR}conf.d/*.conf" -f $HTTPD_CFG_FILE -k $1
            run_user_hook post_start_${cartridge_type}
        fi
    ;;

    graceful-stop|stop)
        # Don't exit on errors on stop.
        set +e
        src_user_hook pre_stop_${cartridge_type}
        httpd_pid=`cat "$HTTPD_PID_FILE" 2> /dev/null`
        ensure_valid_httpd_process "$HTTPD_PID_FILE" "$HTTPD_CFG_FILE"
        /usr/sbin/httpd -C "Include ${PHPMYADMIN_DIR}conf.d/*.conf" -f $HTTPD_CFG_FILE -k $1
        wait_for_stop $httpd_pid
        run_user_hook post_stop_${cartridge_type}
    ;;

    restart|graceful)
        ensure_valid_httpd_process "$HTTPD_PID_FILE" "$HTTPD_CFG_FILE"
        src_user_hook pre_start_${cartridge_type}
        /usr/sbin/httpd -C "Include ${PHPMYADMIN_DIR}conf.d/*.conf" -f $HTTPD_CFG_FILE -k $1
        run_user_hook post_start_${cartridge_type}
    ;;
esac
