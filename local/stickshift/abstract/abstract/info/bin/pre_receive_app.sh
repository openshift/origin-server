#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if [ -z $OPENSHIFT_SKIP_GIT_HOOKS ]
then
    if [ -z "$OPENSHIFT_CI_TYPE" ] || [ -z "$JENKINS_URL" ]
    then
        stop_app.sh
    fi
fi