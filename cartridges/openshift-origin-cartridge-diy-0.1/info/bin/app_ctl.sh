#!/bin/bash -e

cartridge_type='diy-0.1'
source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

translate_env_vars

if ! [ $# -eq 1 ]
then
    echo "Usage: \$0 [start|restart|graceful|graceful-stop|stop]"
    exit 1
fi

run_hook() {
  local path="$OPENSHIFT_REPO_DIR/.openshift/action_hooks/$1"
  if [ -f "$path" -a -x "$path" ]
  then
    "$path"
  else
    return 0
  fi
}

start() {
    _state=`get_app_state`
    if [ -f $OPENSHIFT_HOMEDIR/$cartridge_type/run/stop_lock -o idle = "$_state" ]; then
        echo "Application is explicitly stopped!  Use 'rhc app start -a ${OPENSHIFT_APP_NAME}' to start back up." 1>&2
        return 0
    fi
    set_app_state started
    run_hook start
}

stop() {
    set_app_state stopped
    run_hook stop
}

reload() {
    # Ensure app's not stopped/idle.
    _state=`get_app_state`
    if [ -f $OPENSHIFT_HOMEDIR/$cartridge_type/run/stop_lock -o idle = "$_state" ]; then
        echo "Application is explicitly stopped!  Use 'rhc app start -a ${OPENSHIFT_APP_NAME}' to start back up." 1>&2
        return 0
    fi

    #  Okay to restart (stop + start).
    stop
    start
}


validate_run_as_user

. app_ctl_pre.sh

case "$1" in
    start)
        start
    ;;
    graceful-stop|stop)
        stop
    ;;
    reload)
        reload
    ;;

    restart|graceful)
        stop
        start
    ;;
    status)
        print_user_running_processes `id -u`
    ;;
esac
