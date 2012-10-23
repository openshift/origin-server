#!/bin/bash
set +x

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

if [ -n "$JENKINS_URL" ]
then
	REPO_LINK=${OPENSHIFT_REPO_DIR%/}
  rm -rf $REPO_LINK
  ln -s ~/$WORKSPACE $REPO_LINK
fi

# Export the CI_BUILD variable which will allow the downstream build
# scripts to know they are running in the context of a CI build.
export CI_BUILD=0

set_app_state building

user_pre_build.sh

. build.sh

set -x
