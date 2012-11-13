#!/bin/bash


# Import Environment Variables
for f in ~/.env/*; do
    . $f
done

# Globals
cartridge_type="nodejs-0.6"
cartridge_dir=$OPENSHIFT_HOMEDIR/$cartridge_type

#  Source node configuration.
source /etc/openshift/node.conf


function is_supervisor_running() {
    #  Have a pid file, use it - otherwise return not supervisor.
    [ -f "${cartridge_dir}/run/node.pid" ]  ||  return 1

    #  Have a valid pid, use it - otherwise return not supervisor.
    nodepid=$(cat "${cartridge_dir}/run/node.pid")
    [ -n "$nodepid" ]  ||  return 1

    #  Is the pid a supervisor process.
    if ps --no-heading -ocmd -p $nodepid |  \
       egrep -e "^node\s*/usr/bin/supervisor(.*)" > /dev/null 2>&1; then
       #  Yes, the app server is a supervisor process.
       return 0
    fi

    return 1

}  #  End of function  is_supervisor_running.


#
# main():
#
if [ -f "$OPENSHIFT_REPO_DIR/.openshift/markers/hot_deploy" ]; then
    # Check if supervisor is already running. If not do a restart.
    if ! is_supervisor_running ; then
        ${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/bin/app_ctl.sh restart
    fi
fi

#  Transfer control to the actual post_deploy hook.
exec ${CARTRIDGE_BASE_PATH}/abstract/info/bin/post_deploy.sh "$@"
