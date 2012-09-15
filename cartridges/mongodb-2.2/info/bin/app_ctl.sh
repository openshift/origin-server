#!/bin/bash -e

source /etc/stickshift/stickshift-node.conf
CART_NAME="mongodb"
CART_VERSION="2.2"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Import Environment Variables
for f in ~/.env/*; do
    . $f
done

translate_env_vars

if ! [ $# -eq 1 ]; then
    echo "Usage: \$0 [start|restart|reload|graceful|graceful-stop|stop|status]"
    exit 1
fi

validate_run_as_user

. app_ctl_pre.sh

mongodb_ctl="$OPENSHIFT_HOMEDIR/$CART_NAME-$CART_VERSION/${OPENSHIFT_GEAR_NAME}_mongodb_ctl.sh"

case "$1" in
    start)                    "$mongodb_ctl" start    ;;
    restart|reload|graceful)  "$mongodb_ctl" restart  ;;
    stop|graceful-stop)       "$mongodb_ctl" stop     ;;
    status)                   "$mongodb_ctl" status   ;;
esac
