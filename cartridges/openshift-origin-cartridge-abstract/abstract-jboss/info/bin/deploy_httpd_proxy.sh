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

cartridge_type=$(get_cartridge_name_from_path)

oo-frontend-connect \
    --with-container-uuid "$uuid" \
    --with-container-name "$application" \
    --with-namespace "$namespace" \
    --path "" --target "$IP:8080" --websocket \
    --path "/console" --target "$IP:9990/console" \
    --path "/health" --target "${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/configuration/health.html" --file
