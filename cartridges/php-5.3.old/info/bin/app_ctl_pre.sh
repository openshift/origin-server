#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

export PHPRC="${OPENSHIFT_GEAR_DIR}conf/php.ini"