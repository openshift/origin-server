#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if [ -f "${OPENSHIFT_REPO_DIR}/.openshift/markers/force_clean_build" ]
then
    echo ".openshift/markers/force_clean_build found but disabled for haproxy" 1>&2
fi

source /etc/openshift/node.conf
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

framework_carts=($(get_installed_framework_carts))
primary_framework_cart=${framework_carts[0]}

${CARTRIDGE_BASE_PATH}/${primary_framework_cart}/info/bin/build.sh

# Run user build
user_build.sh
