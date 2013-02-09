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
APP_LOG_PATH=${CART_DIR}/log/ceylon.log

APP_BIN_DIR="$CEYLON_HOME"/bin

CEYLON_PID_FILE="${CART_DIR}/run/ceylon.pid"

# Kill the process given by $1 and its children
killtree() {
    local _pid=$1
    for _child in $(ps -o pid --no-headers --ppid ${_pid}); do
        killtree ${_child}
    done
    echo kill -TERM ${_pid}
    kill -TERM ${_pid}
}

# Check if the jbossas process is running
isrunning() {
    # Check for running app
    if [ -f "$CEYLON_PID_FILE" ]; then
      pid=$(cat $CEYLON_PID_FILE);
      if /bin/ps --pid $pid 1>&2 >/dev/null;
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

			JAVA_OPTS="-Dhttpd.bind.host=${OPENSHIFT_INTERNAL_IP}"

			JAVA_OPTS="$JAVA_OPTS -Dceylon.cache.repo=${CEYLON_USER_REPO}/cache"
			JAVA_OPTS="$JAVA_OPTS -Dcom.redhat.ceylon.common.tool.terminal.width=9999" #do not wrap output

            if [ "${ENABLE_JPDA:-0}" -eq 1 ] ; then
				JAVA_OPTS="$JAVA_OPTS -Xdebug -Xrunjdwp:transport=dt_socket,address=$OPENSHIFT_INTERNAL_IP:8787,server=y,suspend=n"
            fi
            
            export PRESERVE_JAVA_OPTS="true"
			export JAVA_OPTS

			ceylon_repos="--rep http://modules.ceylon-lang.org/test/"
			ceylon_repos="${ceylon_repos} --rep ${CEYLON_USER_REPO}"
			ceylon_repos="${ceylon_repos} --rep ${OPENSHIFT_REPO_DIR}.openshift/config/modules"
            
            source ${OPENSHIFT_REPO_DIR}/.openshift/config/ceylon.properties

			echo "Starting Ceylon module: ${run_module_id}. Using repos: ${ceylon_repos}"

            # Start
            $APP_BIN_DIR/ceylon run ${run_module_id} ${ceylon_repos} >> ${APP_LOG_PATH} 2>&1 &
			CEYLON_PID=$!
			echo $CEYLON_PID > CEYLON_PID_FILE

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
    elif [ -f "$CEYLON_PID_FILE" ]; then
        src_user_hook pre_stop_${cartridge_type}
        pid=$(cat $CEYLON_PID_FILE);
        echo "Sending SIGTERM to ceylon:$pid ..." 1>&2
        killtree $pid
        wait_for_stop $pid
        run_user_hook post_stop_${cartridge_type}
    else 
        echo "Failed to locate Ceylon PID File" 1>&2
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
        app_ctl.sh stop
        app_ctl.sh start
        exit 0
    ;;
    status)
        # Restore stdout and close file descriptor #4
        #exec 1>&4 4>&-
        
        if ! isrunning; then
            echo "Application '${cartridge_type}' is either stopped or inaccessible"
            exit 0
        fi

        echo tailing "$APP_LOG_PATH"
        echo "------ Tail of ${cartridge_type} application ------"
        tail $APP_LOG_PATH
        exit 0
    ;;
esac
