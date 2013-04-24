#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

CART_NAME=$(get_cartridge_name_from_path)

if [ ! -h ${OPENSHIFT_REPO_DIR}/deployments ] && [ ! -h ${OPENSHIFT_HOMEDIR}/${CART_NAME}/${CART_NAME}/standalone/deployments ]
then
  if [ "$(ls ${OPENSHIFT_REPO_DIR}/deployments)" ]; then
    rsync -r --delete-after --exclude=".*" --exclude='*.deployed' --exclude='*.deploying' --exclude='*.isundeploying' ${OPENSHIFT_REPO_DIR}/deployments/ ${OPENSHIFT_HOMEDIR}/${CART_NAME}/${CART_NAME}/standalone/deployments/
  else
    rm -rf ${OPENSHIFT_HOMEDIR}/${CART_NAME}/${CART_NAME}/standalone/deployments/*
  fi
fi

if hot_deploy_marker_is_present; then
  echo "Skipping DB startup and JBoss temp dir cleanup due to presence of hot_deploy marker"
else
  start_dbs

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
