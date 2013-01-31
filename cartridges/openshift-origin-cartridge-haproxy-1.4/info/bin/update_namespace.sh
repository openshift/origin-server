#!/bin/bash

# Exit on any errors
set -e

cartridge_type="haproxy-1.4"
source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

CART_INFO_DIR=${CARTRIDGE_BASE_PATH}/$cartridge_type/info

function print_help {
    echo "Usage: $0 app-name new_namespace old_namespace uuid"

    echo "$0 $@" | logger -p local0.notice -t openshift_origin_haproxy_update_namespace
    exit 1
}

[ $# -eq 4 ] || print_help

application="$1"
new_namespace="$2"
old_namespace="$3"
uuid=$4

setup_app_dir_vars
setup_user_vars

# haproxy_dir=$(get_cartridge_instance_dir "$cartridge_type")
haproxy_dir=$APP_HOME/$cartridge_type
sed -i "s#cookie\s*\(.*\)-$old_namespace#cookie \1-$new_namespace#g;   \
        s#gear-\(.*\)-$old_namespace #gear-\1-$new_namespace #g"     \
    $haproxy_dir/conf/haproxy.cfg
sed -i "s#\(.*\)-$old_namespace\.#\1-$new_namespace\.#g"   \
    $haproxy_dir/conf/gear-registry.db

$CART_INFO_DIR/hooks/cond-reload "$application" "$new_namespace" "$uuid"
