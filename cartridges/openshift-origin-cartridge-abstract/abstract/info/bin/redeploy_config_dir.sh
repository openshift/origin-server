#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if ! [ -e ${OPENSHIFT_HOMEDIR}git/${OPENSHIFT_GEAR_NAME}.git ]
then
    echo "WARNING: No git repo; cannot redeploy."
    exit 0
fi

rm -rf ${OPENSHIFT_REPO_DIR}.openshift/config/* ${OPENSHIFT_REPO_DIR}.openshift/config/.[^.]*

pushd ${OPENSHIFT_HOMEDIR}git/${OPENSHIFT_GEAR_NAME}.git > /dev/null
if ! $(git archive --format=tar HEAD | (cd ${OPENSHIFT_REPO_DIR} && tar --warning=no-timestamp -xf - ".openshift/config/*" > /dev/null 2>&1))
then
	echo "Nothing found in .openshift/config/* to redeploy"
fi
popd > /dev/null
