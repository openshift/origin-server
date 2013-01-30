#!/bin/bash -e

export cartridge_type="ceylon-0.5"
source /etc/openshift/node.conf

source ~/.env/OPENSHIFT_HOMEDIR

${CARTRIDGE_BASE_PATH}/abstract-httpd/info/bin/app_ctl.sh "$@"
