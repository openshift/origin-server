#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

rm -rf ${OPENSHIFT_REPO_DIR}* ${OPENSHIFT_REPO_DIR}.[^.]*
deploy_git_dir.sh . ${OPENSHIFT_REPO_DIR}
