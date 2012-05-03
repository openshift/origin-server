#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

start_dbs

# Run build
#virtualenv --relocatable ${OPENSHIFT_GEAR_DIR}virtenv
#. ./bin/activate

if [ -d ${OPENSHIFT_GEAR_DIR}virtenv ]
then 
    pushd ${OPENSHIFT_GEAR_DIR}virtenv > /dev/null
    . ./bin/activate
    popd > /dev/null
fi

user_deploy.sh