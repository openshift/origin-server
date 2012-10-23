#!/bin/bash
set -e

source /etc/openshift/node.conf

export GIT_SSH=${CARTRIDGE_BASE_PATH}/haproxy-1.4/info/bin/ssh
export GIT_DIR=~/git/${OPENSHIFT_GEAR_NAME}.git
cd $GIT_DIR
rm -rf * 2> /dev/null || :
git clone --bare $1 /tmp/${OPENSHIFT_GEAR_NAME}
mv -f /tmp/${OPENSHIFT_GEAR_NAME}/[^h]* ./ 2> /dev/null || :
git remote add haproxy $1