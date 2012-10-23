#!/bin/bash
if ! [ $# -eq 1 ]
then
    echo "Usage: $0 [start|restart|stop|status]"
    exit 1
fi

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

#  FIXME: Temporary fix for bugz 856487 - Can't add mongodb-2.2 to a ruby1.9 app
#         This needs to be removed once we change how we hande sclized versions
#         of packages.
unset LD_LIBRARY_PATH

export STOPTIMEOUT=10

cartridge_type="mongodb-2.2"

MONGODB_DIR="$OPENSHIFT_HOMEDIR/$cartridge_type/"

if whoami | grep -q root
then
    echo 1>&2
    echo "Please don't run script as root, try:" 1>&2
    echo "runuser --shell /bin/sh $OPENSHIFT_GEAR_UUID ${CART_INFO_DIR}/info/bin/mongodb_ctl.sh" 1>&2
    echo 2>&1
    exit 15
fi

function isrunning() {
    if [ -f $MONGODB_DIR/pid/mongodb.pid ]; then
        mongodb_pid=`cat $MONGODB_DIR/pid/mongodb.pid 2> /dev/null`
        myid=`id -u`
        if `ps --pid $mongodb_pid 2>&1 | grep mongod > /dev/null 2>&1` || `pgrep -x mongod -u $myid > /dev/null 2>&1`
        then
            return 0
        fi
    fi
    return 1
}

function _wait_for_mongod_to_startup() {
    i=0
    while ( (! echo "exit" | mongo $IP > /dev/null 2>&1) ||  \
            [ ! -f ${MONGODB_DIR}/pid/mongodb.pid ]) && [ $i -lt 20 ]; do
        sleep 1
        i=$(($i + 1))
    done
}

function _repair_mongod() {
    authopts=$1
    if ! isrunning ; then
        echo "Attempting to repair MongoDB ..." 1>&2
        tmp_config="/tmp/mongodb.repair.conf"
        grep -ve "fork\s*=\s*true" $MONGODB_DIR/etc/mongodb.conf > $tmp_config
        /usr/bin/mongod $authopts --nojournal --smallfiles -f $tmp_config  \
                                  --repair
        echo "MongoDB repair status = $?" 1>&2
        rm -f $tmp_config
    else
        echo "MongoDB already running - not running repair" 1>&2
    fi
}

function _start_mongod() {
    authopts=${1:-"--auth"}
    /usr/bin/mongod $authopts --nojournal --smallfiles --quiet  \
                    -f $MONGODB_DIR/etc/mongodb.conf run >/dev/null 2>&1 &
    _wait_for_mongod_to_startup
    if ! isrunning; then
       _repair_mongod "$authopts"
       /usr/bin/mongod $authopts --nojournal --smallfiles --quiet  \
                       -f $MONGODB_DIR/etc/mongodb.conf run >/dev/null 2>&1 &
       _wait_for_mongod_to_startup
    fi
}

function start() {
    if only_cart_on_gear $cartridge_type; then
        set_app_state started
    fi

    if ! isrunning
    then
        src_user_hook pre_start_mongodb-2.2
        _start_mongod  "$1"
        run_user_hook post_start_mongodb-2.2
    else
        echo "MongoDB already running" 1>&2
    fi
}

function stop() {
    if only_cart_on_gear $cartridge_type; then
        set_app_state stopped
    fi

    if [ -f $MONGODB_DIR/pid/mongodb.pid ]; then
    	pid=$( /bin/cat $MONGODB_DIR/pid/mongodb.pid )
    fi

    if [ -n "$pid" ]; then
        src_user_hook pre_stop_mongodb-2.2
        /bin/kill $pid
        ret=$?
        if [ $ret -eq 0 ]; then
            TIMEOUT="$STOPTIMEOUT"
            while [ $TIMEOUT -gt 0 ] && [ -f "$MONGODB_DIR/pid/mongodb.pid" ]; do
                /bin/kill -0 "$pid" >/dev/null 2>&1 || break
                sleep 1
                let TIMEOUT=${TIMEOUT}-1
            done
        fi
        run_user_hook post_stop_mongodb-2.2
    else
        if `pgrep -x mongod > /dev/null 2>&1`
        then
        	echo "Warning: MongoDB process exists without a pid file.  Use force-stop to kill." 1>&2
        else
            echo "MongoDB already stopped" 1>&2
        fi
    fi
}

case "$1" in
    start)
        start
    ;;
    start-noauth)
        start --noauth
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
            echo "MongoDB is running" 1>&2
        else
            echo "MongoDB is stopped" 1>&2
        fi
        exit 0
    ;;
esac
