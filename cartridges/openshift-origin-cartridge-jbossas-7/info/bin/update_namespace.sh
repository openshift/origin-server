#!/bin/bash

# Exit on any errors
set -e
 
source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

CART_INFO_DIR=${CARTRIDGE_BASE_PATH}/jbossas-7/info

function print_help {
    echo "Usage: $0 app-name new_namespace old_namespace uuid"

    echo "$0 $@" | logger -p local0.notice -t openshift_origin_jboss_update_namespace

    exit 1
}

[ $# -eq 4 ] || print_help

application="$1"
new_namespace="$2"
old_namespace="$3"
uuid=$4

setup_app_dir_vars
setup_user_vars

OPENSHIFT_JBOSSAS_CLUSTER="$APP_HOME/.env/OPENSHIFT_JBOSSAS_CLUSTER"

if [ -f $OPENSHIFT_JBOSSAS_CLUSTER ]
then
  echo "Updating OPENSHIFT_JBOSSAS_CLUSTER with new namespace, ${old_namespace} => ${new_namespace}"
  sed -i "s/${old_namespace}/${new_namespace}/g" $APP_HOME/.env/OPENSHIFT_JBOSSAS_CLUSTER
  client_message "IMPORTANT: It is recommended that you restart your application to ensure all namespace related configurations are updated in the application's environment."
else
  echo "Not updating OPENSHIFT_JBOSSAS_CLUSTER in response to namespace update as the file doesn't exist"
fi
