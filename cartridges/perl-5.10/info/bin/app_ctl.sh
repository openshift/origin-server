#!/bin/bash

# Set cart name and version + source node config.
CART_NAME="perl"
CART_VERSION="5.10"
source /etc/stickshift/stickshift-node.conf

# Import Environment Variables
for f in ~/.env/*; do
    . $f
done

# Set the extra lib paths we need.
export REPOLIB="${OPENSHIFT_REPO_DIR}libs/"
export LOCALSITELIB="${OPENSHIFT_GEAR_DIR}perl5lib/lib/perl5/"
export PERL5LIB="$REPOLIB:$LOCALSITELIB"

# Federate to the abstract httpd app_ctl.sh
exec ${CARTRIDGE_BASE_PATH}/abstract-httpd/info/bin/app_ctl.sh "$@"

