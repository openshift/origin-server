#!/bin/bash -e

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if ! [ $# -eq 1 ]
then
    echo "Usage: $0 [start|graceful-stop|stop]"
    exit 1
fi


validate_run_as_user

case "$1" in
    start)
        if [ -f ${OPENSHIFT_10GEN_MMS_AGENT_GEAR_DIR}run/stop_lock ]
        then
            echo "Application is explicitly stopped!  Use 'rhc app cartridge start -a ${OPENSHIFT_GEAR_NAME} -c 10gen-mms-agent-0.1' to start back up." 1>&2
            exit 0
        fi

        if ps -ef | grep ${OPENSHIFT_GEAR_UUID}_agent.py | grep -qv grep > /dev/null 2>&1; then
            echo "Application is already running!  Use 'rhc app cartridge restart -a ${OPENSHIFT_GEAR_NAME} -c 10gen-mms-agent-0.1' to restart." 1>&2
            exit 0
        fi

        #
        # Remove the compiled versions of the settings.py file and reset the mms credentials from the file in repo
        # This is required so that any user changes to credentials in this file can be picked up and recompiled
        #
        rm -f ${OPENSHIFT_10GEN_MMS_AGENT_GEAR_DIR}mms-agent/settings.pyc ${OPENSHIFT_10GEN_MMS_AGENT_GEAR_DIR}mms-agent/settings.pyo
        
        new_mms_key_line=`cat ${OPENSHIFT_GEAR_DIR}repo/.openshift/mms/settings.py | grep -E "^mms_key\s*=.*"`
        new_secret_key_line=`cat ${OPENSHIFT_GEAR_DIR}repo/.openshift/mms/settings.py | grep -E "^secret_key\s*=.*"`
        sed -i "s/^mms_key\s*=.*/${new_mms_key_line}/g" ${OPENSHIFT_10GEN_MMS_AGENT_GEAR_DIR}mms-agent/settings.py
        sed -i "s/^secret_key\s*=.*/${new_secret_key_line}/g" ${OPENSHIFT_10GEN_MMS_AGENT_GEAR_DIR}mms-agent/settings.py


        nohup python ${OPENSHIFT_10GEN_MMS_AGENT_GEAR_DIR}mms-agent/${OPENSHIFT_GEAR_UUID}_agent.py > ${OPENSHIFT_10GEN_MMS_AGENT_GEAR_DIR}logs/agent.log 2>&1 &
        echo $! > ${OPENSHIFT_10GEN_MMS_AGENT_GEAR_DIR}run/mms-agent.pid
    ;;

    graceful-stop|stop)
        if [ -f ${OPENSHIFT_10GEN_MMS_AGENT_GEAR_DIR}run/mms-agent.pid ]
        then
            mms_agent_pid=`cat ${OPENSHIFT_10GEN_MMS_AGENT_GEAR_DIR}run/mms-agent.pid 2> /dev/null`
            kill -9 $mms_agent_pid > /dev/null
            rm -f ${OPENSHIFT_10GEN_MMS_AGENT_GEAR_DIR}run/mms-agent.pid > /dev/null
        else
            if ps -ef | grep ${OPENSHIFT_GEAR_UUID}_agent.py | grep -qv grep > /dev/null 2>&1; then
                echo "Failed to stop 10gen-mms-agent-0.1 as the pid file is missing!" 1>&2
                exit 1
            else
                echo "The 10-gen-mms-agent-0.1 is already stopped!" 1>&2
            fi
        fi
    ;;
esac