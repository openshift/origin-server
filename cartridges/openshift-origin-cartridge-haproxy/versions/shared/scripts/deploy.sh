#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source /etc/openshift/node.conf
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

start_attached_dbs

${CARTRIDGE_BASE_PATH}/abstract/info/bin/deploy.sh

#  For auto-scaling disabled, ensure the haproxy control daemon is stopped.
disable_as="${OPENSHIFT_REPO_DIR}/.openshift/markers/disable_auto_scaling"
[ -f "$disable_as" ]  &&  haproxy_ctld_daemon stop > /dev/null 2>&1

framework_carts=($(get_installed_framework_carts))
primary_framework_cart=${framework_carts[0]}

# Sync to the other gears
${CARTRIDGE_BASE_PATH}/${primary_framework_cart}/info/bin/sync_gears.sh

#user_deploy.sh
