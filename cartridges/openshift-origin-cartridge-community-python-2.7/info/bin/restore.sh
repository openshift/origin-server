#!/bin/bash
cartridge_type='python-2.7'
source /etc/openshift/node.conf
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util
source ${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/lib/util

include_git="$1"

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

# Import Environment Variables
source ${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/bin/source_env_vars

if [ "$include_git" = "INCLUDE_GIT" ]
then
  # prevent feeding the tarball to pre-receive on stdin
  ~/git/${OPENSHIFT_GEAR_NAME}.git/hooks/pre-receive < /dev/null 1>&2
  echo "Removing old git repo: ~/git/${OPENSHIFT_GEAR_NAME}.git/" 1>&2
  /bin/rm -rf ~/git/${OPENSHIFT_GEAR_NAME}.git/[^h]*/*
else
  stop_app.sh 1>&2
fi

echo "Removing old data dir: ~/app-root/data/*" 1>&2
/bin/rm -rf ~/app-root/data/* ~/app-root/data/.[^.]*

restore_tar.sh $include_git

for db in $(get_attached_databases)
do
    restore_cmd=${CARTRIDGE_BASE_PATH}/${db}/info/bin/restore.sh
    echo "Running extra restore for $db" 1>&2
    $restore_cmd
done

if [ "$include_git" = "INCLUDE_GIT" ]
then
  GIT_DIR=~/git/${OPENSHIFT_GEAR_NAME}.git/ ~/git/${OPENSHIFT_GEAR_NAME}.git/hooks/post-receive 1>&2  
else
  start_app.sh 1>&2
fi
