#!/bin/bash

CART_NAME="python"
CART_VERSION="2.7"
cartridge_type="$CART_NAME-$CART_VERSION"
source /etc/openshift/node.conf
source ${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/lib/util

# Import Environment Variables
source ${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/bin/source_env_vars

start_dbs

cart_deploy=$OPENSHIFT_HOMEDIR/$cartridge_type/bin/deploy
[ -f "$cart_deploy" ]   &&  source "$cart_deploy"

user_deploy.sh

