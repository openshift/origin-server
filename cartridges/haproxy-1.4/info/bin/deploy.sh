#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source /etc/stickshift/stickshift-node.conf
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

${CARTRIDGE_BASE_PATH}/abstract/info/bin/deploy.sh

#  For auto-scaling disabled, ensure the haproxy control daemon is stopped.
disable_as="${OPENSHIFT_REPO_DIR}/.openshift/markers/disable_auto_scaling"
[ -f "$disable_as" ]  &&  haproxy_ctld_daemon stop > /dev/null 2>&1

# Sync to the other gears
${CARTRIDGE_BASE_PATH}/${OPENSHIFT_GEAR_TYPE}/info/bin/sync_gears.sh

#user_deploy.sh
