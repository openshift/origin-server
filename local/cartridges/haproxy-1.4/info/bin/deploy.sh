#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source /etc/stickshift/stickshift-node.conf
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Sync to the other gears
${CARTRIDGE_BASE_PATH}/${OPENSHIFT_GEAR_TYPE}/info/bin/sync_gears.sh

#user_deploy.sh
