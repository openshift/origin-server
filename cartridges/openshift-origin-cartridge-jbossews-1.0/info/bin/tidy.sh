#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

CART_NAME=$(get_cartridge_name_from_path)
CART_NS=$(get_cartridge_namespace_from_path)
CART_DIR=$(get_env_var_dynamic "OPENSHIFT_${CART_NS}_CART_DIR")
JBOSS_DIR=${CART_DIR}/${CART_NAME}

standalone_tmp=${JBOSS_DIR}/standalone/tmp/
if [ -d $standalone_tmp ]
then
    client_message "Emptying tmp dir: $standalone_tmp"
    rm -rf $standalone_tmp/* $standalone_tmp/.[^.]*
fi