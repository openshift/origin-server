#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

start_dbs

# Run build

cart_instance_dir=$OPENSHIFT_HOMEDIR/python-2.6

virtenv_dir=$cart_instance_dir/virtenv

if [ -f $virtenv_dir/bin/activate ]
then 
    pushd $virtenv_dir > /dev/null
    /bin/rm -f lib64
    virtualenv --system-site-packages $virtenv_dir
    . ./bin/activate
    popd > /dev/null
fi

user_deploy.sh
