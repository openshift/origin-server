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
    # FIXME: Fix next line to use $virtenv when typeless gears merge is done.
    z_virtenv_dir=~/python-2.6/virtenv
    /bin/rm -f lib64
    virtualenv --system-site-packages "$z_virtenv_dir"
    . ./bin/activate
    popd > /dev/null
fi

user_deploy.sh
