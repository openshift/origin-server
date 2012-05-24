#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

standalone_tmp=${OPENSHIFT_GEAR_DIR}${OPENSHIFT_GEAR_TYPE}/standalone/tmp/
if [ -d $standalone_tmp ]
then
    client_message "Emptying tmp dir: $standalone_tmp"
    rm -rf $standalone_tmp/* $standalone_tmp/.[^.]*
fi