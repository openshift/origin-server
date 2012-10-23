#!/bin/bash -e

CART_NAME="ruby"
CART_VERSION="1.9"
export cartridge_type="ruby-1.9"
source /etc/openshift/node.conf
httpd_app_ctl_sh=${CARTRIDGE_BASE_PATH}/abstract-httpd/info/bin/app_ctl.sh

myargs="$@"
/usr/bin/scl enable ruby193 "$httpd_app_ctl_sh $myargs"
