#!/bin/bash

#
# Create Frontend Routes
#
function print_help {
    echo "Usage: $0 app-name namespace uuid IP"

    echo "$0 $@" | logger -p local0.notice -t openshift_origin_jenkins_deploy_httpd_proxy
    exit 1
}

[ $# -eq 4 ] || print_help


application="$1"
namespace=`basename $2`
uuid=$3
IP=$4

source "/etc/openshift/node.conf"

oo-frontend-connect \
    --with-container-uuid "$uuid" \
    --with-container-name "$application" \
    --with-namespace "$namespace" \
    --path "" --target "$IP:8080" --websocket --tohttps \
    --path "/health" --target "${CARTRIDGE_BASE_PATH}/jenkins-1.4/info/configuration/health" --file
