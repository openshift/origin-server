#!/bin/bash -e

export cartridge_type="php-5.3"
source /etc/stickshift/stickshift-node.conf
${CARTRIDGE_BASE_PATH}/abstract-httpd/info/bin/app_ctl.sh "$@"
