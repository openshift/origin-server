#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

pushd ${OPENSHIFT_HOMEDIR}git/${OPENSHIFT_GEAR_NAME}.git > /dev/null
client_message "Running 'git prune'"
git prune
client_message "Running 'git gc --aggressive'"
git gc --aggressive
popd > /dev/null

client_message "Emptying log dir: ${OPENSHIFT_LOG_DIR}"
rm -rf ${OPENSHIFT_LOG_DIR}* ${OPENSHIFT_LOG_DIR}.[^.]*

client_message "Emptying tmp dir: ${OPENSHIFT_TMP_DIR}"
rm -rf ${OPENSHIFT_TMP_DIR}* ${OPENSHIFT_TMP_DIR}.[^.]* 2>/dev/null
if [ $? -eq 1 ]; then
    client_message "Failed to empty tmp dir: ${OPENSHIFT_TMP_DIR}"
fi

if [ -d ${OPENSHIFT_GEAR_DIR}tmp/ ]
then
    client_message "Emptying tmp dir: ${OPENSHIFT_GEAR_DIR}tmp/"
    rm -rf ${OPENSHIFT_GEAR_DIR}tmp/* ${OPENSHIFT_GEAR_DIR}tmp/.[^.]*
fi
