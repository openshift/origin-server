#!/bin/bash

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

export APPDIR="${OPENSHIFT_GEAR_DIR}"

# Federate call to abstract httpd.
${CARTRIDGE_BASE_PATH}/abstract-httpd/info/bin/app_ctl.sh "$@"
