#!/bin/bash

#
# Create Frontend Routes
#
function print_help {
    echo "Usage: $0 app-name namespace uuid"

    echo "$0 $@" | logger -p local0.notice -t openshift_origin_deploy_httpd_proxy
    exit 1
}

[ $# -eq 4 ] || print_help


application="$1"
namespace=`basename $2`
uuid=$3
IP=$4
cartridge_type="postgresql-8.4"

source "/etc/openshift/node.conf"

CART_INFO_DIR=${CARTRIDGE_BASE_PATH}/$cartridge_type/info

oo-frontend-connect \
    --with-container-uuid "$uuid" \
    --with-container-name "$application" \
    --with-namespace "$namespace" \
    --path "" --target "$CART_INFO_DIR/configuration/index.html" --file \
    --path "/health" --target "$CART_INFO_DIR/configuration/index.html" --file
