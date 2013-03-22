#!/bin/bash

# This hook is what drives the initial shutdown of the application prior to 
# applying incoming commits. Because it must respect the presence of the
# hot_deploy marker, this becomes a bit tricky as we must take into account
# the possibility that the marker is being added or removed during the
# commit, possibly for the first time. The stop should only occur if the
# marker is present and will remain present after the commit is applied.

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import environment variables
for f in ~/.env/*
do
    . $f
done

# Only handle app stopping here if hooks are enabled and if this
# Jenkins is not embedded
if [ -z $OPENSHIFT_SKIP_GIT_HOOKS ]
then
    if [ -z "$OPENSHIFT_CI_TYPE" ] || [ -z "$JENKINS_URL" ]
    then
        #touch $OPENSHIFT_HOMEDIR$OPENSHIFT_APP_NAME/repo/deployments/*.*ar
        pre_stop_app
    fi
fi
