#!/bin/bash -e

# Set cart name and version + source node config.
CART_NAME="perl"
CART_VERSION="5.10"
export cartridge_type="perl-5.10"
source /etc/openshift/node.conf

# Import Environment Variables
for f in ~/.env/*; do
    . $f
done

OPENSHIFT_PERL_DIR=${OPENSHIFT_HOMEDIR}/${cartridge_type}

# Set the extra lib paths we need.
export REPOLIB="${OPENSHIFT_REPO_DIR}libs/"
export LOCALSITELIB="${OPENSHIFT_PERL_DIR}/perl5lib/lib/perl5/"
export PERL5LIB="$REPOLIB:$LOCALSITELIB"

# Federate to the abstract httpd app_ctl.sh
${CARTRIDGE_BASE_PATH}/abstract-httpd/info/bin/app_ctl.sh "$@"
