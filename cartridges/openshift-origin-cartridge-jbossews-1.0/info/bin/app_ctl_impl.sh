#!/bin/bash -e

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*; do . $f; done

cartridge_type=$(get_cartridge_name_from_path)

if ! [ $# -eq 1 ]
then
    echo "Usage: \$0 [start|restart|graceful|graceful-stop|stop|threaddump]"
    exit 1
fi

CART_DIR=$OPENSHIFT_HOMEDIR/$cartridge_type

APP_JBOSS=${CART_DIR}/${cartridge_type}
APP_JBOSS_TMP_DIR="$APP_JBOSS"/tmp
APP_JBOSS_BIN_DIR="$APP_JBOSS"/bin

# For debugging, capture script output into app tmp dir
#exec 4>&1 > /dev/null 2>&1  # Link file descriptor 4 with stdout, saves stdout.
#exec > "$APP_JBOSS_TMP_DIR/${cartridge_type}-${cartridge_type}_ctl-$1.log" 2>&1

# Kill the process given by $1 and its children
killtree() {
    local _pid=$1
    for _child in $(ps -o pid --no-headers --ppid ${_pid}); do
        killtree ${_child}
    done
    echo kill -9 ${_pid}
    kill -9 ${_pid}
}
# Check if the jbossas process is running
isrunning() {
    # Check for running app
    if [ -f "$JBOSS_PID_FILE" ]; then
      jbpid=$(cat $JBOSS_PID_FILE);
      running=`/bin/ps --no-headers --pid $jbpid`
      if test -n "$running";
      then
        return 0
      fi
    fi
    # not running
    return 1
}
# Check if the server http port is up
function ishttpup() {
    let count=0
    while [ ${count} -lt 24 ]
    do
        if /usr/sbin/lsof -P -n -i "@${OPENSHIFT_INTERNAL_IP}:8080" | grep "(LISTEN)" > /dev/null; then
            echo "Found ${OPENSHIFT_INTERNAL_IP}:8080 listening port"
            return 0
        fi
        let count=${count}+1
        sleep 2
    done
    return 1
}



function start_app() {
    if [ -f "${OPENSHIFT_REPO_DIR}/.openshift/markers/enable_jpda" ]; then
       ENABLE_JPDA=1
    fi

    _state=`get_app_state`
    if [ -f $CART_DIR/run/stop_lock -o idle = "$_state" ]; then
        echo "Application is explicitly stopped!  Use 'rhc app start -a ${OPENSHIFT_APP_NAME}' to start back up." 1>&2
    else
        # Check for running app
        if isrunning; then
            echo "Application is already running" 1>&2
        else
            src_user_hook pre_start_${cartridge_type}
            set_app_state started
            # Start
            jopts="${JAVA_OPTS}"
            
            export CATALINA_HOME=$APP_JBOSS
            export CATALINA_BASE=$APP_JBOSS
            export CATALINA_TMPDIR=$APP_JBOSS/tmp
            
            [ "${ENABLE_JPDA:-0}" -eq 1 ] && jopts="-Xdebug -Xrunjdwp:transport=dt_socket,address=$OPENSHIFT_INTERNAL_IP:8787,server=y,suspend=n ${JAVA_OPTS}"
            JAVA_OPTS="${jopts}" ${CART_DIR}/jbossews-1.0/bin/tomcat6 start > ${APP_JBOSS_TMP_DIR}/${cartridge_type}.log 2>&1 &
            PROCESS_ID=$!
            
            echo $PROCESS_ID > $JBOSS_PID_FILE
            if ! ishttpup; then
                echo "Timed out waiting for http listening port"
                exit 1
            fi
            run_user_hook post_start_${cartridge_type}
        fi
    fi
}

function stop_app() {
    set_app_state stopped
    if ! isrunning; then
        echo "Application is already stopped" 1>&2
    elif [ -f "$JBOSS_PID_FILE" ]; then
        src_user_hook pre_stop_${cartridge_type}
        pid=$(cat $JBOSS_PID_FILE);
        echo "Sending SIGTERM to jboss:$pid ..." 1>&2
        killtree $pid
        run_user_hook post_stop_${cartridge_type}
    else 
        echo "Failed to locate JBOSS PID File" 1>&2
    fi
}

function threaddump() {
    if ! isrunning; then
        echo "Application is stopped"
        exit 1
    elif [ -f "$JBOSS_PID_FILE" ]; then
        pid=$(cat $JBOSS_PID_FILE);
        java_pid=`ps h --ppid $pid -o '%p'`
        kill -3 $java_pid
    else 
        echo "Failed to locate JBOSS PID File"
    fi
}


JBOSS_PID_FILE="$CART_DIR/run/jboss.pid"

case "$1" in
    start)
        start_app
        exit 0
    ;;
    graceful-stop|stop)
        stop_app
        exit 0
    ;;
    restart|graceful)
        #stop_app
        #start_app
        #exit 0
        app_ctl_impl.sh stop
        app_ctl_impl.sh start
    ;;
    threaddump)
        threaddump
    ;;
    status)
        # Restore stdout and close file descriptor #4
        #exec 1>&4 4>&-
        
        if ! isrunning; then
            echo "Application '${cartridge_type}' is either stopped or inaccessible"
            exit 0
        fi

        echo tailing "$APP_JBOSS/logs/catalina.out"
        echo "------ Tail of ${cartridge_type} application catalina.out ------"
        tail "$APP_JBOSS/logs/catalina.out"
        exit 0
    ;;
esac
