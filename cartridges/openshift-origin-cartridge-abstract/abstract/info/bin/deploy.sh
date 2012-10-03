#!/bin/bash

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

start_dbs

user_deploy.sh
