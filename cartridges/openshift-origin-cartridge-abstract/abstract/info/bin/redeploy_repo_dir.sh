#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if [ -z "${GIT_DIR}" ]
then
    GIT_DIR=~/git/${OPENSHIFT_GEAR_NAME}.git/
fi

if [ -d "${OPENSHIFT_REPO_DIR}/" -a ! "${OPENSHIFT_REPO_DIR}/" -ef "/" ]; then
    rm -rf ${OPENSHIFT_REPO_DIR}/* ${OPENSHIFT_REPO_DIR}/.[^.]*
fi
deploy_git_dir.sh ${GIT_DIR} ${OPENSHIFT_REPO_DIR}
