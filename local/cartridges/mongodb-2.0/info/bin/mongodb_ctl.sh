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

if whoami | grep -q root
then
    echo 1>&2
    echo "Please don't run script as root, try:" 1>&2
    echo "runuser --shell /bin/sh $OPENSHIFT_GEAR_UUID $MONGODB_DIR/${OPENSHIFT_GEAR_NAME}_mongodb_ctl.sh" 1>&2
    echo 2>&1
    exit 15
fi

MONGODB_DIR="$OPENSHIFT_HOMEDIR/mongodb-2.0/"

isrunning() {
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

repair() {
    if ! isrunning ; then
        echo "Attempting to repair MongoDB ..." 1>&2
        tmp_config="/tmp/mongodb.repair.conf"
        grep -ve "fork\s*=\s*true" $MONGODB_DIR/etc/mongodb.conf > $tmp_config
        /usr/bin/mongod --auth --nojournal --smallfiles -f $tmp_config --repair
        echo "MongoDB repair status = $?" 1>&2
        rm -f $tmp_config
    else
        echo "MongoDB already running - not running repair" 1>&2
    fi
}

start() {
    if ! isrunning
    then
        /usr/bin/mongod --auth --nojournal --smallfiles --quiet -f $MONGODB_DIR/etc/mongodb.conf run >/dev/null 2>&1 &
    else
        echo "MongoDB already running" 1>&2
    fi
}

stop() {
    if [ -f $MONGODB_DIR/pid/mongodb.pid ]; then
    	pid=$( /bin/cat $MONGODB_DIR/pid/mongodb.pid )
    fi

    if [ -n "$pid" ]; then
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
    stop)
        stop
    ;;
    restart)
        stop
        start
    ;;
    repair)
        repair
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
