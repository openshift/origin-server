#!/bin/bash

include_git="$1"

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if [ "$include_git" = "INCLUDE_GIT" ]
then
  echo "Restoring ~/git/${OPENSHIFT_GEAR_NAME}.git and ~/app/data" 1>&2
  /bin/tar --strip=2 --overwrite -xmz "./*/app/data" "./*/git" --exclude="./*/git/${OPENSHIFT_GEAR_NAME}.git/hooks" 1>&2  
else
  echo "Restoring ~/app/data" 1>&2
  /bin/tar --strip=2 --overwrite -xmz "./*/app/data" 1>&2
fi
