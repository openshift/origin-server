#!/bin/bash
if ! [ $# -eq 1 ]
then
    echo "Usage: $0 [start|restart|stop|status]"
    exit 1
fi

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

export STOPTIMEOUT=10

cartridge_type="mysql-5.1"

MYSQL_DIR="$OPENSHIFT_HOMEDIR/mysql-5.1/"

source /etc/openshift/node.conf
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util
CART_INFO_DIR=${CARTRIDGE_BASE_PATH}/embedded/mysql-5.1/info
source ${CART_INFO_DIR}/lib/util

if whoami | grep -q root
then
    echo 1>&2
    echo "Please don't run script as root, try:" 1>&2
    echo "runuser --shell /bin/sh $OPENSHIFT_GEAR_UUID ${CART_INFO_DIR}/info/bin/mysql_ctl.sh" 1>&2
    echo 2>&1
    exit 15
fi

isrunning() {
    if [ -f $MYSQL_DIR/pid/mysql.pid ]; then
        mysql_pid=`cat $MYSQL_DIR/pid/mysql.pid 2> /dev/null`
        myid=`id -u`
        if `ps --pid $mysql_pid > /dev/null 2>&1` || `pgrep -x mysqld_safe -u $myid > /dev/null 2>&1`
        then
            return 0
        fi
    fi
    return 1
}

start() {
    if only_cart_on_gear $cartridge_type; then
        set_app_state started
    fi

    if ! isrunning
    then
        src_user_hook pre_start_mysql-5.1
        /usr/bin/mysqld_safe --defaults-file=$MYSQL_DIR/etc/my.cnf >/dev/null 2>&1 &
        wait_to_start_db_as_user
        run_user_hook post_start_mysql-5.1
    else
        echo "MySQL already running" 1>&2
    fi
}

stop() {

    if only_cart_on_gear $cartridge_type; then
        set_app_state stopped
    fi

    if [ -f $MYSQL_DIR/pid/mysql.pid ]; then
        src_user_hook pre_stop_mysql-5.1
        pid=$( /bin/cat $MYSQL_DIR/pid/mysql.pid )
        /bin/kill $pid
        ret=$?
        if [ $ret -eq 0 ]; then
            TIMEOUT="$STOPTIMEOUT"
            while [ $TIMEOUT -gt 0 ] && [ -f "$MYSQL_DIR/pid/mysql.pid" ]; do
                /bin/kill -0 "$pid" >/dev/null 2>&1 || break
                sleep 1
                let TIMEOUT=${TIMEOUT}-1
            done
        fi
        run_user_hook post_stop_mysql-5.1
    else
        if `pgrep -x mysqld_safe > /dev/null 2>&1`
        then
        	echo "Warning: MySQL process exists without a pid file.  Use force-stop to kill." 1>&2
        else
            echo "MySQL already stopped" 1>&2
        fi
    fi
}

case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        stop
        start
    ;;
    status)
        if isrunning
        then
            echo "MySQL is running" 1>&2
        else
            echo "MySQL is stopped" 1>&2
        fi
        exit 0
    ;;
esac
