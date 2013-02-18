#!/bin/bash

#
# Create Frontend Routes
#
function print_help {
    echo "Usage: $0 app-name namespace uuid IP"

    echo "$0 $@" | logger -p local0.notice -t openshift_origin_deploy_httpd_proxy
    exit 1
}

[ $# -eq 4 ] || print_help


application="$1"
namespace=`basename $2`
uuid=$3
IP=$4

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

setup_app_dir_vars
setup_user_vars

export CART_INFO_DIR=${CARTRIDGE_BASE_PATH}/embedded/haproxy-1.4/info

oo-frontend-connect \
    --with-container-uuid "$uuid" \
    --with-container-name "$application" \
    --with-namespace "$namespace" \
    --path "" --target "$IP:8080" --websocket -o "connections=-1" \
    --path "/health" --target "${CART_INFO_DIR}/configuration/health.html" --file \
    --path "/haproxy-status" --target "$IP2:8080/"
