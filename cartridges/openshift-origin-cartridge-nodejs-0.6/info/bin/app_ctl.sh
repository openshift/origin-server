#!/bin/bash

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

STOPTIMEOUT=10
FMT="%a %b %d %Y %H:%M:%S GMT%z (%Z)"

function print_missing_package_json_warning() {
       cat <<DEPRECATED
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  It is highly recommended that you add a package.json
  file to your application.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
DEPRECATED

}

function _is_node_service_running() {
    if [ -f $cartridge_dir/run/node.pid ]; then
        node_pid=$( cat $cartridge_dir/run/node.pid 2> /dev/null )
        myid=$( id -u )
        if `ps --pid $node_pid 2>&1 | grep node > /dev/null 2>&1`  ||  \
           `pgrep -x node -u $myid > /dev/null 2>&1`; then
            return 0
        fi
    fi

    return 1

}  #  End of function  _is_node_running.


function _status_node_service() {
    if _is_node_service_running; then
        app_state="running"
    else
        app_state="either stopped or inaccessible"
    fi

    echo "Application '$OPENSHIFT_APP_NAME' is $app_state" 1>&2

}  #  End of function  _status_node_service.


function _get_main_script_from_package_json() {
    node <<NODE_EOF
try {
  var zmain = require('$OPENSHIFT_REPO_DIR/package.json').main;
  if (typeof zmain === 'undefined') {
    console.log('server.js');
  }
  else {
    console.log(zmain);
  }
} catch(ex) {
  console.log('server.js');
}
NODE_EOF

}  #  End of function  _get_main_script_from_package_json.


function _start_node_service() {
    _state=`get_app_state`
    if [ -f $cartridge_dir/run/stop_lock -o idle = "$_state" ]; then
        echo "Application is explicitly stopped!  Use 'rhc app start -a ${OPENSHIFT_APP_NAME}' to start back up." 1>&2
        return 0
    else
        # Check if service is running.
        if _is_node_service_running; then
            echo "Application '$OPENSHIFT_APP_NAME' is already running" 1>&2
            return 0
        fi
    fi

    set_app_state started

    #  Got here - it means that we need to start up Node.

    src_user_hook pre_start_${cartridge_type}

    envf="$cartridge_dir/conf/node.env"
    logf="$OPENSHIFT_NODEJS_LOG_DIR/node.log"

    #  Source environment if it exists.
    [ -f "$envf" ]  &&  source "$envf"

    #  Ensure we have script file.
    node_app=${node_app:-"server.js"}

    if [ ! -h "$OPENSHIFT_REPO_DIR/../node_modules" ]; then
       ln -s ../../nodejs-0.6/node_modules $OPENSHIFT_REPO_DIR/../node_modules
    fi

    pushd "$OPENSHIFT_REPO_DIR" > /dev/null
    {
       echo "`date +"$FMT"`: Starting application '$OPENSHIFT_APP_NAME' ..."
       if [ ! -f "$OPENSHIFT_REPO_DIR/package.json" ]; then
           echo "    Script       = $node_app"
           echo "    Script Args  = $node_app_args"
           echo "    Node Options = $node_opts"
       fi
    } >> $logf


    if [ -f "$OPENSHIFT_REPO_DIR/package.json" ]; then
         script_n_opts="$(_get_main_script_from_package_json)"
         executor_cmdline="npm start -d"
    else
         #  Backward compatibility.
         print_missing_package_json_warning
         script_n_opts="$node_opts $node_app $node_app_args"
         executor_cmdline="node $node_opts $node_app $node_app_args"
    fi

    if [ -f "$OPENSHIFT_REPO_DIR/.openshift/markers/hot_deploy" ]; then
        nohup supervisor -e 'node|js|coffee' -- $script_n_opts  >> $logf 2>&1 &
    else
        nohup $executor_cmdline >> $logf 2>&1 &
    fi

    ret=$?
    npid=$!
    popd > /dev/null
    if [ $ret -eq 0 ]; then
        echo "$npid" > "$cartridge_dir/run/node.pid"
        run_user_hook post_start_${cartridge_type}
    else
        echo "Application '$OPENSHIFT_APP_NAME' failed to start - $ret" 1>&2
    fi

}  #  End of function  _start_node_service.


function _stop_node_service() {
    if [ -f $cartridge_dir/run/node.pid ]; then
        node_pid=$( cat $cartridge_dir/run/node.pid 2> /dev/null )
    fi

    if [ -n "$node_pid" ]; then
        set_app_state stopped

        src_user_hook pre_stop_${cartridge_type}

        logf="$OPENSHIFT_NODEJS_LOG_DIR/node.log"
        echo "`date +"$FMT"`: Stopping application '$OPENSHIFT_APP_NAME' ..." >> $logf
        /bin/kill $node_pid
        ret=$?
        if [ $ret -eq 0 ]; then
            TIMEOUT="$STOPTIMEOUT"
            while [ $TIMEOUT -gt 0 ]  &&  _is_node_service_running ; do
                /bin/kill -0 "$node_pid" >/dev/null 2>&1 || break
                sleep 1
                let TIMEOUT=${TIMEOUT}-1
            done
        fi

        # Make Node go down forcefully if it is still running.
        if _is_node_service_running ; then
           killall -9 node > /dev/null 2>&1  ||  :
        fi

        echo "`date +"$FMT"`: Stopped Node application '$OPENSHIFT_APP_NAME'" >> $logf
        rm -f $cartridge_dir/run/node.pid

        run_user_hook post_stop_${cartridge_type}
    else
        if `pgrep -x node -u $(id -u)  > /dev/null 2>&1`; then
            echo "Warning: Application '$OPENSHIFT_APP_NAME' Node server exists without a pid file.  Use force-stop to kill." 1>&2
        fi
    fi
}  #  End of function  _stop_node_service.


function _restart_node_service() {
    _stop_node_service
    _start_node_service

}  #  End of function  _restart_node_service.



#
#  main():
#

# Ensure arguments.
if ! [ $# -eq 1 ]; then
    echo "Usage: $0 [start|restart|graceful|graceful-stop|stop|status]"
    exit 1
fi

# Source utility functions.
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*; do
    . $f
done

cartridge_type="nodejs-0.6"
cartridge_dir=$OPENSHIFT_HOMEDIR/$cartridge_type

translate_env_vars

validate_run_as_user

# Handle commands.
case "$1" in
    start)               _start_node_service    ;;
    restart|graceful)    _restart_node_service  ;;
    graceful-stop|stop)  _stop_node_service     ;;
    status)              _status_node_service   ;;
esac

