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

source /etc/stickshift/stickshift-node.conf

if [ "${OPENSHIFT_GEAR_TYPE}" != "haproxy-1.4" ]
then
    ${CARTRIDGE_BASE_PATH}/${OPENSHIFT_GEAR_TYPE}/info/bin/build.sh
fi

# Run user build
user_build.sh
