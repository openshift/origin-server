#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if [ -x ${OPENSHIFT_REPO_DIR}.openshift/action_hooks/build ]
then
    echo "Running .openshift/action_hooks/build"
    ${OPENSHIFT_REPO_DIR}.openshift/action_hooks/build
fi
