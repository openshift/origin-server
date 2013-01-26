#!/bin/bash

CART_NAME="community-pod"
CART_VERSION="0.1"
cartridge_type="$CART_NAME-$CART_VERSION"
source /etc/openshift/node.conf
source ${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/lib/util

# Import Environment Variables
for f in ~/.env/*; do
    source $f
done

source ${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/bin/source_cartridge_vars

start_dbs

cart_deploy=$OPENSHIFT_HOMEDIR/$OPENSHIFT_COMMUNITYPOD_CART/bin/deploy
[ -f "$cart_deploy" ]   &&  source "$cart_deploy"

user_deploy.sh

