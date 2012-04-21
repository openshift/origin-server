#!/bin/bash

include_git="$1"

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if [ "$include_git" = "INCLUDE_GIT" ]
then
  ~/git/${OPENSHIFT_GEAR_NAME}.git/hooks/pre-receive 1>&2
  echo "Removing old git repo: ~/git/${OPENSHIFT_GEAR_NAME}.git/" 1>&2
  /bin/rm -rf ~/git/${OPENSHIFT_GEAR_NAME}.git/[^h]*/*
else
  stop_app.sh 1>&2
fi

echo "Removing old data dir: ~/${OPENSHIFT_GEAR_NAME}/data/*" 1>&2
/bin/rm -rf ~/${OPENSHIFT_GEAR_NAME}/data/* ~/${OPENSHIFT_GEAR_NAME}/data/.[^.]*

restore_tar.sh $include_git

for cmd in `awk 'BEGIN { for (a in ENVIRON) if (a ~ /_RESTORE$/) print ENVIRON[a] }'`
do
    echo "Running extra restore: $(/bin/basename $cmd)" 1>&2
    $cmd
done

if [ "$include_git" = "INCLUDE_GIT" ]
then
  GIT_DIR=~/git/${OPENSHIFT_GEAR_NAME}.git/ ~/git/${OPENSHIFT_GEAR_NAME}.git/hooks/post-receive 1>&2  
else
  start_app.sh 1>&2
fi
