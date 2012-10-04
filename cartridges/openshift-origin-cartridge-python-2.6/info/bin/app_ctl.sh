#!/bin/bash

export cartridge_type="python-2.6"
source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

cart_instance_dir=$OPENSHIFT_HOMEDIR/${cartridge_type}

export APPDIR="${cart_instance_dir}"

# Federate call to abstract httpd.
${CARTRIDGE_BASE_PATH}/abstract-httpd/info/bin/app_ctl.sh "$@"
