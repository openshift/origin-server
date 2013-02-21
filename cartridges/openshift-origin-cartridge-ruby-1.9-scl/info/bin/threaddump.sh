#!/bin/bash -e

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if ! [ $# -eq 2 ]
then
    echo "Usage: \$0 APP_ID UUID"
    exit 1
fi

cart_instance_dir=$OPENSHIFT_HOMEDIR/ruby-1.9
ruby_tmp_dir=$cart_instance_dir/tmp

PID=$(ps -u $(id -u $2) -o pid,command | grep -v grep | grep 'Rack:.*'$2 | awk 'BEGIN {FS=" "}{print $1}')

if [ "$PID" = "" ]; then
    _state_file=${OPENSHIFT_HOMEDIR}/app-root/runtime/.state
    _state=unknown
    if [ -f "$_state_file" ]; then
        _state=`cat "$_state_file"`
    fi

    if [ -f ${ruby_tmp_dir}/stop_lock -o stopped = "$_state" ]; then
        echo "Application is stopped.  You must start the application and access it by its URL (http://${OPENSHIFT_GEAR_DNS}) before you can take a thread dump."
    else
        # idle = "$_state"
        echo "Application is inactive. Ruby/Rack applications must be accessed by their URL (http://${OPENSHIFT_GEAR_DNS}) before you can take a thread dump."
    fi
else
    if ! kill -3 $PID; then
      echo "Failed to signal application. Please retry after restarting application and access it by its URL (http://${OPENSHIFT_GEAR_DNS})"
    fi
fi
