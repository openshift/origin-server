#!/bin/bash

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

start_dbs

user_deploy.sh
