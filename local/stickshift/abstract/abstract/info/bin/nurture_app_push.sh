#!/bin/bash

stickshift_server=$1

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

curl -s -O /dev/null -d "json_data={\"app_uuid\":\"${OPENSHIFT_GEAR_UUID}\",\"action\":\"push\"}" https://${stickshift_server}/broker/nurture >/dev/null 2>&1 &
