#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

start_dbs

standalone_tmp=${OPENSHIFT_GEAR_DIR}${OPENSHIFT_GEAR_TYPE}/standalone/tmp
if [ -d $standalone_tmp ]
then
    for d in $standalone_tmp/*
    do
        if [ -d $d ]
        then
            echo "Emptying tmp dir: $d"
            rm -rf $d/* $d/.[^.]*
        fi
    done
fi

user_deploy.sh