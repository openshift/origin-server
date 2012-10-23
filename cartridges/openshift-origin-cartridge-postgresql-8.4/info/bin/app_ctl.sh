#!/bin/bash -e

export cartridge_type="postgresql-8.4"

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

cmd=""

case "$1" in
    start)                    cmd="start"    ;;
    restart|reload|graceful)  cmd="restart"  ;;
    stop|graceful-stop)       cmd="stop"     ;;
    status)                   cmd="status"   ;;
esac

if [ "${cmd}" == "" ]; then
    exit 0
fi

if [ -f $OPENSHIFT_HOMEDIR/.env/.uservars/OPENSHIFT_POSTGRESQL_DB_GEAR_UUID ]; then
    postgresql_ctl="ssh $OPENSHIFT_POSTGRESQL_DB_GEAR_UUID@$OPENSHIFT_POSTGRESQL_DB_GEAR_DNS ${CARTRIDGE_BASE_PATH}/$cartridge_type/info/bin/postgresql_ctl.sh $cmd"
else
    postgresql_ctl="$CARTRIDGE_BASE_PATH/$cartridge_type/info/bin/postgresql_ctl.sh $cmd"
fi

$postgresql_ctl
