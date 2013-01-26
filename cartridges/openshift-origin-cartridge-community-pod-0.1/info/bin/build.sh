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

CONFIG_DIR="$CARTRIDGE_BASE_PATH/diy-0.1/info/configuration"
export OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.base.xml"
if `echo $OPENSHIFT_GEAR_DNS | egrep -qe "\.rhcloud\.com"`; then
    export OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.rhcloud.xml"
fi

cart_build=$OPENSHIFT_HOMEDIR/$OPENSHIFT_COMMUNITYPOD_CART/bin/build
[ -f "$cart_build" ]   &&  source "$cart_build"

user_build.sh
