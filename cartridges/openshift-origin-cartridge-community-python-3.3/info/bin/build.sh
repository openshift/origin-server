#!/bin/bash

CART_NAME="python"
CART_VERSION="3.3"
cartridge_type="$CART_NAME-$CART_VERSION"
source /etc/openshift/node.conf
source ${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/lib/util

# Import Environment Variables
source ${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/bin/source_env_vars


CONFIG_DIR="$CARTRIDGE_BASE_PATH/$cartridge_type/info/configuration"
export OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.base.xml"
if `echo $OPENSHIFT_GEAR_DNS | egrep -qe "\.rhcloud\.com"`; then
    export OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.rhcloud.xml"
fi

cart_build=$OPENSHIFT_HOMEDIR/$cartridge_type/bin/build
[ -f "$cart_build" ]   &&  source "$cart_build"

user_build.sh
