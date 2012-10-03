#!/bin/bash -e

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

cartridge_type="jenkins-1.4"
cartridge_dir=$OPENSHIFT_HOMEDIR/$cartridge_dir

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
    pid=`pgrep -f ".*java.*-jar.*jenkins.war.*--httpListenAddress=${OPENSHIFT_INTERNAL_IP}.*" 2> /dev/null`
    if [ -n "$pid" ]
    then
        return 0
    fi
    # not running
    return 1
}

start_jenkins() {
    src_user_hook pre_start_${cartridge_type}
    set_app_state started
    /usr/lib/jvm/jre-1.6.0/bin/java \
        -Dcom.sun.akuma.Daemon=daemonized \
        -Djava.awt.headless=true \
        -DJENKINS_HOME=$OPENSHIFT_DATA_DIR/ \
        -Dhudson.slaves.NodeProvisioner.recurrencePeriod=500 \
        -Dhudson.slaves.NodeProvisioner.initialDelay=100 \
        -Dhudson.slaves.NodeProvisioner.MARGIN=100 \
        -Dhudson.model.UpdateCenter.never=true \
        -Xmx168m \
        -XX:MaxPermSize=100m \
        -jar /usr/lib/jenkins/jenkins.war \
        --ajp13Port=-1 \
        --controlPort=-1 \
        --logfile=$OPENSHIFT_JENKINS_LOG_DIR/jenkins.log \
        --daemon \
        --httpPort=8080 \
        --debug=5 \
        --handlerCountMax=45 \
        --handlerCountMaxIdle=20 \
        --httpListenAddress="$OPENSHIFT_INTERNAL_IP" &
    echo $! > /dev/null
    if [ $? -eq 0 ]; then
        run_user_hook post_start_${cartridge_type}
    fi
}

stop_jenkins() {
    src_user_hook pre_stop_${cartridge_type}
    set_app_state stopped
    kill -TERM $pid > /dev/null 2>&1
    wait_for_stop $pid
    run_user_hook post_stop_${cartridge_type}
}

case "$1" in
    start)
        _state=`get_app_state`
        if [ -f ${cartridge_dir}/run/stop_lock -o idle = "$_state" ]
        then
            echo "Application is explicitly stopped!  Use 'rhc app start -a ${cartridge_type}' to start back up." 1>&2
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
        # the plugin automatically does a reload prior to a build - so a no-op here
        exit 0
    ;;
    status)
        if ! isrunning; then
            echo "Application '${cartridge_type}' is either stopped or inaccessible"
            exit 0
        fi
        print_user_running_processes `id -u`
        exit 0
    ;;
esac
