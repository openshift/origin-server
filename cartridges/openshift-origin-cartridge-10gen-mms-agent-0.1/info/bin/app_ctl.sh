#!/bin/bash -e

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

cartridge_type="10gen-mms-agent-0.1"
cartridge_dir=${OPENSHIFT_HOMEDIR}/${cartridge_type}

if ! [ $# -eq 1 ]
then
    echo "Usage: $0 [start|graceful-stop|stop]"
    exit 1
fi


validate_run_as_user

case "$1" in
    start)
        if [ -f ${cartridge_dir}/run/stop_lock ]
        then
            echo "Application is explicitly stopped!  Use 'rhc app cartridge start -a ${OPENSHIFT_APP_NAME} -c ${cartridge_type}' to start back up." 1>&2
            exit 0
        fi

        if ps -ef | grep ${OPENSHIFT_GEAR_UUID}_agent.py | grep -qv grep > /dev/null 2>&1; then
            echo "Application is already running!  Use 'rhc app cartridge restart -a ${OPENSHIFT_APP_NAME} -c ${cartridge_type}' to restart." 1>&2
            exit 0
        fi
        src_user_hook pre_start_10gen_mms_agent-0.1
        #
        # Remove the compiled versions of the settings.py file and reset the mms credentials from the file in repo
        # This is required so that any user changes to credentials in this file can be picked up and recompiled
        #
        rm -f ${cartridge_dir}/mms-agent/settings.pyc ${cartridge_dir}/mms-agent/settings.pyo
        
        new_mms_key_line=`cat ${OPENSHIFT_REPO_DIR}/.openshift/mms/settings.py | grep -E "^mms_key\s*=.*"`
        new_secret_key_line=`cat ${OPENSHIFT_REPO_DIR}/.openshift/mms/settings.py | grep -E "^secret_key\s*=.*"`
        sed -i "s/^mms_key\s*=.*/${new_mms_key_line}/g" ${cartridge_dir}/mms-agent/settings.py
        sed -i "s/^secret_key\s*=.*/${new_secret_key_line}/g" ${cartridge_dir}/mms-agent/settings.py


        nohup python ${cartridge_dir}/mms-agent/${OPENSHIFT_GEAR_UUID}_agent.py > ${cartridge_dir}/logs/agent.log 2>&1 &
        echo $! > ${cartridge_dir}/run/mms-agent.pid
        run_user_hook post_start_10gen_mms_agent-0.1
    ;;

    graceful-stop|stop)
        if [ -f ${cartridge_dir}/run/mms-agent.pid ]
        then
            src_user_hook pre_stop_10gen_mms_agent-0.1
            mms_agent_pid=`cat ${cartridge_dir}/run/mms-agent.pid 2> /dev/null`
            kill -9 $mms_agent_pid > /dev/null
            rm -f ${cartridge_dir}/run/mms-agent.pid > /dev/null
            run_user_hook post_stop_10gen_mms_agent-0.1
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
