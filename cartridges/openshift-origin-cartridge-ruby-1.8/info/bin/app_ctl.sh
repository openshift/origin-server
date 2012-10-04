#!/bin/bash -e

export cartridge_type="ruby-1.8"
source /etc/openshift/node.conf
${CARTRIDGE_BASE_PATH}/abstract-httpd/info/bin/app_ctl.sh "$@"