#!/bin/bash -e

source "/etc/stickshift/stickshift-node.conf"
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

validate_run_as_user

. app_ctl_pre.sh

isrunning() {
    # Check for running app
    #pid=`cat ${OPENSHIFT_RUN_DIR}jenkins.pid 2> /dev/null`
    pid=`pgrep -f ".*java.*-jar.*jenkins.war.*--httpListenAddress=${OPENSHIFT_INTERNAL_IP}.*" 2> /dev/null`
    if [ -n "$pid" ]
    then
        return 0
    fi
    # not running
    return 1
}

start_jenkins() {
    set_app_state started
    /usr/lib/jvm/jre-1.6.0/bin/java \
        -Dcom.sun.akuma.Daemon=daemonized \
        -Djava.awt.headless=true \
        -DJENKINS_HOME=$OPENSHIFT_DATA_DIR/ \
        -Dhudson.slaves.NodeProvisioner.recurrencePeriod=500 \
        -Dhudson.slaves.NodeProvisioner.initialDelay=100 \
        -Dhudson.slaves.NodeProvisioner.MARGIN=100 \
        -Xmx168m \
        -XX:MaxPermSize=100m \
        -jar /usr/lib/jenkins/jenkins.war \
        --ajp13Port=-1 \
        --controlPort=-1 \
        --logfile=$OPENSHIFT_LOG_DIR/jenkins.log \
        --daemon \
        --httpPort=8080 \
        --debug=5 \
        --handlerCountMax=45 \
        --handlerCountMaxIdle=20 \
        --httpListenAddress="$OPENSHIFT_INTERNAL_IP" &
    echo $! > /dev/null
}

stop_jenkins() {
    set_app_state stopped
    kill -TERM $pid > /dev/null 2>&1
    wait_for_stop $pid
}

case "$1" in
    start)
        _state=`get_app_state`
        if [ -f ${OPENSHIFT_GEAR_DIR}run/stop_lock -o idle = "$_state" ]
        then
            echo "Application is explicitly stopped!  Use 'rhc app start -a ${OPENSHIFT_GEAR_NAME}' to start back up." 1>&2
            exit 0
        else
            if isrunning
            then
                echo "Application is already running!" 1>&2
                exit 0
            fi
            start_jenkins
        fi
    ;;
    graceful-stop|stop)
        if isrunning
        then
            stop_jenkins
        else
            echo "Application is already stopped!" 1>&2
            exit 0
        fi
    ;;
    restart|graceful)
        if isrunning
        then
            stop_jenkins
        fi
        start_jenkins
    ;;
    reload)
        if isrunning
        then
            if ! out=$(jenkins_reload "${JENKINS_USERNAME}" "${JENKINS_PASSWORD}" "${JENKINS_URL}" 2>&1)
            then
                # An error occurred reloading jenkins configuration
                echo "Could not reload Jenkins server '${OPENSHIFT_GEAR_NAME}' configuration:" 1>&2
                echo "   $out" 1>&2
                exit 1
            fi
        else
            echo "Application is stopped!" 1>&2
            exit 0
        fi
    ;;
    status)
        if ! isrunning; then
            echo "Application '${OPENSHIFT_GEAR_NAME}' is either stopped or inaccessible"
            exit 0
        fi
        print_user_running_processes `id -u`
        exit 0
    ;;
esac
