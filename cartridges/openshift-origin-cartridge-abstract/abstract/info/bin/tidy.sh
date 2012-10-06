#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

pushd ${OPENSHIFT_HOMEDIR}git/${OPENSHIFT_APP_NAME}.git > /dev/null
client_message "Running 'git prune'"
git prune
client_message "Running 'git gc --aggressive'"
git gc --aggressive
popd > /dev/null

for logdir in `awk 'BEGIN {
                           for (a in ENVIRON)
                           if (a ~ /LOG_DIR$/)
                           print ENVIRON[a] }'`
do
    client_message "Emptying log dir: ${logdir}"
    rm -rf ${logdir}* ${logdir}.[^.]*
done
                      
for tmpdir in `awk 'BEGIN {
                           for (a in ENVIRON)
                           if (a ~ /TMP_DIR$/)
                           print ENVIRON[a] }'`
do
    client_message "Emptying tmp dir: ${tmpdir}"
    rm -rf ${tmpdir}* ${tmpdir}.[^.]* 2>/dev/null || :
done
