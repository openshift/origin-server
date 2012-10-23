#!/bin/bash
cartridge_type="postgresql-8.4"

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util
CART_INFO_DIR=$CARTRIDGE_BASE_PATH/$cartridge_type/info
source ${CART_INFO_DIR}/lib/util

export PGHOST="$OPENSHIFT_POSTGRESQL_DB_HOST"
export PGPORT="${OPENSHIFT_POSTGRESQL_DB_PORT:-5432}"
export PGUSER="${OPENSHIFT_POSTGRESQL_DB_USERNAME:-'admin'}"
export PGPASSWORD="${OPENSHIFT_POSTGRESQL_DB_PASSWORD}"

start_database_as_user 1>&2

echo "postgresql-8.4" > $OPENSHIFT_DATA_DIR/postgresql_dbname

dbuser=${OPENSHIFT_POSTGRESQL_DB_GEAR_UUID:-$OPENSHIFT_GEAR_UUID}
echo "$dbuser" > $OPENSHIFT_DATA_DIR/postgresql_dbuser

# Dump all databases but remove any sql statements that drop, create and alter
# the admin and user roles.
rexp="^\s*\(DROP\|CREATE\|ALTER\)\s*ROLE\s*\($OPENSHIFT_GEAR_UUID\|admin\).*"
/usr/bin/pg_dumpall -c | sed "/$rexp/d;" |   \
            /bin/gzip -v > $OPENSHIFT_DATA_DIR/postgresql_dump_snapshot.gz

if [ ! ${PIPESTATUS[0]} -eq 0 ]
then
    echo 1>&2
    echo "WARNING!  Could not dump PostgreSQL databases!  Continuing anyway" 1>&2
    echo 1>&2
    /bin/rm -rf $OPENSHIFT_DATA_DIR/postgresql_dump_snapshot.gz
fi
