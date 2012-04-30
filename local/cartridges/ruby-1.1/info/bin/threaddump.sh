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

PID=`ps -e -o pid,command | grep Rack | grep $1 | grep $2 | awk 'BEGIN {FS=" "}{print $1}'`

if [$PID .eq ""]; then
    _state_file=${OPENSHIFT_RUNTIME_DIR:-${OPENSHIFT_GEAR_DIR}runtime}/.state
    _state=unknown
    if [ -f "$_state_file" ]; then
        _state=`cat "$_state_file"`
    fi

    if [ -f ${OPENSHIFT_GEAR_DIR}run/stop_lock -o stopped = "$_state" ]; then
        echo "Application is stopped.  You must start the application and access it by its URL (http://${OPENSHIFT_GEAR_DNS}) before you can take a thread dump."
    else
        # idle = "$_state"
        echo "Application is inactive. Ruby/Rack applications must be accessed by their URL (http://${OPENSHIFT_GEAR_DNS}) before you can take a thread dump."
    fi
else 
    kill -3 $PID
fi
