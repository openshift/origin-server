#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

export APPDIR="${OPENSHIFT_GEAR_DIR}"