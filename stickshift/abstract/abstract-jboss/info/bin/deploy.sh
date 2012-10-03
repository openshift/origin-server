#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

if hot_deploy_marker_is_present; then
  echo "Skipping DB startup and JBoss temp dir cleanup due to presence of hot_deploy marker"
else
  start_dbs

  standalone_tmp=${OPENSHIFT_GEAR_DIR}${OPENSHIFT_GEAR_TYPE}/standalone/tmp
  if [ -d $standalone_tmp ]
  then
      for d in $standalone_tmp/*
      do
          if [ -d $d ]
          then
              echo "Emptying tmp dir: $d"
              rm -rf $d/* $d/.[^.]*
          fi
      done
  fi
fi

user_deploy.sh
