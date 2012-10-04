#!/bin/bash

CART_NAME="diy"
CART_VERSION="0.1"
source /etc/openshift origin/openshift-origin-node.conf

# Import Environment Variables
for f in ~/.env/*; do
    source $f
done

CONFIG_DIR="$CARTRIDGE_BASE_PATH/diy-0.1/info/configuration"
OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.base.xml"
if `echo $OPENSHIFT_GEAR_DNS | egrep -qe "\.(stg|int|dev)\.rhcloud\.com"`
then 
    export OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.stg.xml"
elif `echo $OPENSHIFT_GEAR_DNS | grep -qe "\.rhcloud\.com"`
then
    export OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.prod.xml"
fi

user_build.sh
