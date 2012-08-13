#!/bin/bash

CONFIG_DIR="$CARTRIDGE_BASE_PATH/$OPENSHIFT_GEAR_TYPE/info/configuration"
OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.base.xml"
if `echo $OPENSHIFT_GEAR_DNS | grep -q .stg.rhcloud.com` || `echo $OPENSHIFT_GEAR_DNS | grep -q .dev.rhcloud.com`
then 
	OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.stg.xml"
elif `echo $OPENSHIFT_GEAR_DNS | grep -q .rhcloud.com`
then
	OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.prod.xml"
fi

user_build.sh
