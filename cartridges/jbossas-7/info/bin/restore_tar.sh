#!/bin/bash

include_git="$1"

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if [ "$include_git" = "INCLUDE_GIT" ]
then
  echo "Restoring ~/git/${OPENSHIFT_GEAR_NAME}.git, ~/${OPENSHIFT_GEAR_NAME}/data and ~/.m2" 1>&2
  /bin/tar --strip=2 --overwrite -xmz "./*/${OPENSHIFT_GEAR_NAME}/data" "./*/git" "./*/.m2" --exclude="./*/git/${OPENSHIFT_GEAR_NAME}.git/hooks" 1>&2  
else
  echo "Restoring ~/${OPENSHIFT_GEAR_NAME}/data" 1>&2
  /bin/tar --strip=2 --overwrite -xmz "./*/${OPENSHIFT_GEAR_NAME}/data" 1>&2
fi