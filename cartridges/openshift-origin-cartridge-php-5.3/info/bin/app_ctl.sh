#!/bin/bash -e

export cartridge_type="php-5.3"
source /etc/openshift/node.conf

source ~/.env/OPENSHIFT_HOMEDIR
export PHPRC="${OPENSHIFT_HOMEDIR}/$cartridge_type/conf/php.ini"

${CARTRIDGE_BASE_PATH}/abstract-httpd/info/bin/app_ctl.sh "$@"
