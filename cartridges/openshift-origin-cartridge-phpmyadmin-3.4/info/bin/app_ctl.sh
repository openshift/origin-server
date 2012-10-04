#!/bin/bash -e

cartridge_type="phpmyadmin-3.4"
source /etc/openshift/node.conf
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

phpmyadmin_ctl="${CARTRIDGE_BASE_PATH}/$cartridge_type/info/bin/phpmyadmin_ctl.sh"

case "$1" in
    start)                    "$phpmyadmin_ctl" start    ;;
    restart|reload|graceful)  "$phpmyadmin_ctl" restart  ;;
    stop|graceful-stop)       "$phpmyadmin_ctl" stop     ;;
    status)                   "$phpmyadmin_ctl" status   ;;
esac
