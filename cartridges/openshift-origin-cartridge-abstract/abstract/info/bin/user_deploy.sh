#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if [ -x ${OPENSHIFT_REPO_DIR}.openshift/action_hooks/deploy ]
then
    echo "Running .openshift/action_hooks/deploy"
    ${OPENSHIFT_REPO_DIR}.openshift/action_hooks/deploy
fi
