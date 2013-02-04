#!/bin/bash -e

export cartridge_type="ceylon-0.5"
source "/etc/openshift/node.conf"

if ! [ $# -eq 1 ]
then
    echo "Usage: \$0 [start|restart|stop]"
    exit 1
fi

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done


source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util


CART_DIR=$OPENSHIFT_HOMEDIR/$cartridge_type

APP_DIR=${CART_DIR}/${cartridge_type}
APP_LOG_PATH=${CART_DIR}/${cartridge_type}/log/ceylon.log

APP_BIN_DIR="$APP_DIR"/bin

PID_FILE="${CART_DIR}/run/ceylon.pid"

# Check if the jbossas process is running
isrunning() {
    # Check for running app
    if [ -f "$APP_PID_FILE" ]; then
      pid=$(cat $APP_PID_FILE);
      if /bin/ps --pid $pid 1>&2 >/dev/null;
      then
        return 0
      fi
    fi
    # not running
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
            [ "${ENABLE_JPDA:-0}" -eq 1 ] && jopts="-Xdebug -Xrunjdwp:transport=dt_socket,address=$OPENSHIFT_INTERNAL_IP:8787,server=y,suspend=n ${JAVA_OPTS}"
            #TODO prepare ceylon.sh
            JAVA_OPTS="${jopts}" $APP_BIN_DIR/ceylon.sh > ${APP_LOG_PATH} 2>&1 &
            PROCESS_ID=$!
            echo $PROCESS_ID > $PID_FILE
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
    elif [ -f "$PID_FILE" ]; then
        src_user_hook pre_stop_${cartridge_type}
        pid=$(cat $JBOSS_PID_FILE);
        echo "Sending SIGTERM to jboss:$pid ..." 1>&2
        killtree $pid
        run_user_hook post_stop_${cartridge_type}
    else 
        echo "Failed to locate JBOSS PID File" 1>&2
    fi
}

case "$1" in
    start)
        start_app
        exit 0
    ;;
    stop)
        stop_app
        exit 0
    ;;
    restart)
        #stop_app
        #start_app
        #exit 0
        app_ctl.sh stop
        app_ctl.sh start
    ;;
    status)
        # Restore stdout and close file descriptor #4
        #exec 1>&4 4>&-
        
        if ! isrunning; then
            echo "Application '${cartridge_type}' is either stopped or inaccessible"
            exit 0
        fi

        echo tailing "$APP_DIR/log/server.log"
        echo "------ Tail of ${cartridge_type} application server.log ------"
        tail "$APP_DIR/log/server.log"
        exit 0
    ;;
esac
