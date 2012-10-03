#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

if hot_deploy_marker_is_present; then
  echo "Skipping DB startup and JBoss temp dir cleanup due to presence of hot_deploy marker"
else
  start_dbs

  CART_NAME=$(get_cartridge_name_from_path)
  CART_NS=$(get_cartridge_namespace_from_path)
  CART_DIR=$(get_env_var_dynamic "OPENSHIFT_${CART_NS}_CART_DIR")
  JBOSS_DIR=${CART_DIR}/${CART_NAME}

  standalone_tmp=${JBOSS_DIR}/standalone/tmp
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
