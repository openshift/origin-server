#!/bin/bash

# Add lib/util loading
source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

post_start_app $1

#rm -f $OPENSHIFT_HOMEDIR$OPENSHIFT_APP_NAME/repo/deployments/*.*ar.undeployed
#rm -f $OPENSHIFT_HOMEDIR$OPENSHIFT_APP_NAME/repo/deployments/*.*ar.failed

