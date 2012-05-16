#!/bin/bash -e

source /etc/stickshift/stickshift-node.conf
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

export STOPTIMEOUT=20

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

export HAPROXY_PID="${OPENSHIFT_HOMEDIR}/haproxy-1.4/run/haproxy.pid"

if ! [ $# -eq 1 ]
then
    echo "Usage: \$0 [start|restart|graceful|graceful-stop|stop]"
    exit 1
fi

validate_run_as_user

. app_ctl_pre.sh

isrunning() {
    if [ -f "${HAPROXY_PID}" ]; then
        haproxy_pid=`$HAPROXY_PID 2> /dev/null`
        if `ps --pid $haproxy_pid > /dev/null 2>&1` || `pgrep -x haproxy > /dev/null 2>&1`
        then
            return 0
        fi
    fi
    return 1
}

function wait_to_start() {
   ep=$(grep "listen stats" $OPENSHIFT_HOMEDIR/haproxy-1.4/conf/haproxy.cfg | sed 's#listen\s*stats\s*\(.*\)#\1#')
   i=0
   while ( ! curl "http://$ep/haproxy-status/;csv" &> /dev/null )  && [ $i -lt 10 ]; do
       sleep 1
       i=$(($i + 1))
   done

   if [ $i -ge 10 ]; then
      echo "`date`: haproxy-status check - max retries ($i) exceeded" 1>&2
   fi
}

start() {
    set_app_state started
    if ! isrunning
    then
        src_user_hook pre_start_${CARTRIDGE_TYPE}
        /usr/sbin/haproxy -f $OPENSHIFT_HOMEDIR/haproxy-1.4/conf/haproxy.cfg > /dev/null 2>&1
        haproxy_ctld_daemon stop > /dev/null 2>&1  || :
        haproxy_ctld_daemon start > /dev/null 2>&1
        wait_to_start
        run_user_hook post_start_${CARTRIDGE_TYPE}
    else
        echo "Haproxy already running" 1>&2
        wait_to_start
    fi
}


stop() {
    src_user_hook pre_stop_${CARTRIDGE_TYPE}
    set_app_state stopped
    haproxy_ctld_daemon stop > /dev/null 2>&1
    if [ -f $HAPROXY_PID ]; then
        pid=$( /bin/cat "${HAPROXY_PID}" )
        /bin/kill $pid
        ret=$?
        if [ $ret -eq 0 ]; then
            TIMEOUT="$STOPTIMEOUT"
            while [ $TIMEOUT -gt 0 ] && [ -f "$HAPROXY_PID" ]; do
                /bin/kill -0 "$pid" >/dev/null 2>&1 || break
                sleep .5
                let TIMEOUT=${TIMEOUT}-1
            done
        fi
    else
        if `pgrep -x haproxy > /dev/null 2>&1`
        then
            echo "Warning: Haproxy process exists without a pid file.  Use force-stop to kill." 1>&2
        else
            echo "Haproxy already stopped" 1>&2
        fi
    fi
    run_user_hook post_stop_${CARTRIDGE_TYPE}
}


function restart() {
   stop || pkill haproxy || :
   start
}


function _reload_haproxy_service() {
    [ -n "$1" ]  &&  zopts="-sf $1"
    src_user_hook pre_start_${CARTRIDGE_TYPE}
    /usr/sbin/haproxy -f $OPENSHIFT_HOMEDIR/haproxy-1.4/conf/haproxy.cfg ${zopts} > /dev/null 2>&1
    run_user_hook post_start_${CARTRIDGE_TYPE}

}

function _reload_service() {
    [ -f $HAPROXY_PID ]  &&  zpid=$( /bin/cat "${HAPROXY_PID}" )
    i=0
    while (! _reload_haproxy_service "$zpid" )  && [ $i -lt 60 ]; do
        sleep 2
        i=$(($i + 1))
        echo "`date`: Retrying haproxy service reload - attempt #$((i+1)) ... "
    done

    wait_to_start
}

reload() {
    if ! isrunning; then
       start
    else
       echo "`date`: Reloading haproxy service " 1>&2
       _reload_service
    fi
    haproxy_ctld_daemon stop > /dev/null 2>&1   ||  :
    haproxy_ctld_daemon start > /dev/null 2>&1
}


case "$1" in
    start)               start               ;;
    graceful-stop|stop)  stop                ;;
    restart)             restart             ;;
    graceful|reload)     reload              ;;
    force-stop)          pkill haproxy       ;;
    status)              print_running_processes `id -u` ;;
    # FIXME:  status should just report on haproxy not all the user's processes.
esac
