#!/bin/bash
cartridge_type="postgresql-8.4"

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if [ -f "$OPENSHIFT_DATA_DIR/postgresql_dump_snapshot.gz" ]
then
    source "/etc/openshift/node.conf"
    source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util
    CART_INFO_DIR=$CARTRIDGE_BASE_PATH/$cartridge_type/info
    source ${CART_INFO_DIR}/lib/util
    CART_INSTANCE_DIR=${OPENSHIFT_HOMEDIR}/$cartridge_type

    start_database_as_user

    old_dbname="postgresql-8.4"
    old_dbuser=${OPENSHIFT_POSTGRESQL_DB_GEAR_UUID:-$OPENSHIFT_GEAR_UUID}
    [ -f "$OPENSHIFT_DATA_DIR/postgresql_dbname" ] &&  old_dbname=$(cat "$OPENSHIFT_DATA_DIR/postgresql_dbname")
    [ -f "$OPENSHIFT_DATA_DIR/postgresql_dbuser" ] &&  old_dbuser=$(cat "$OPENSHIFT_DATA_DIR/postgresql_dbuser")

    dbname="postgresql-8.4"
    dbuser=${OPENSHIFT_POSTGRESQL_DB_GEAR_UUID:-$OPENSHIFT_GEAR_UUID}

    # Restore the PostgreSQL databases
    rexp="\(DROP\|CREATE\)\s*DATABASE\s*$old_dbname"
    owner_rexp="\(CREATE\s*DATABASE\)\s*\(.*\)\s*OWNER\s*=\s*[^ ;]*"
    pgrole_rexp="\(CREATE\|DROP\)\s*ROLE\s*postgres;"

    export PGDATABASE="$OPENSHIFT_APP_NAME"
    export PGHOST="$OPENSHIFT_POSTGRESQL_DB_HOST"
    export PGPORT="${OPENSHIFT_POSTGRESQL_DB_PORT:-5432}"
    export PGUSER="${OPENSHIFT_POSTGRESQL_DB_USERNAME:-'admin'}"
    export PGPASSWORD="${OPENSHIFT_POSTGRESQL_DB_PASSWORD}"

    /bin/zcat $OPENSHIFT_DATA_DIR/postgresql_dump_snapshot.gz |         \
        sed "s#$rexp#\\1 DATABASE $dbname#g;                            \
             s#$owner_rexp#\\1 \\2 OWNER = \"$dbuser\"#g;               \
             s#\\connect $old_dbname#\\connect $dbname#g;               \
             s#$old_dbuser#$dbuser#g;                                   \
             /$pgrole_rexp/d;" |                                        \
                 /usr/bin/psql -d postgres

    if [ ! ${PIPESTATUS[1]} -eq 0 ]
    then
        echo 1>&2
        echo "Error: Could not import PostgreSQL Database!  Continuing..." 1>&2
        echo 1>&2
    fi
    $CART_INFO_DIR/bin/cleanup.sh

else
    echo "PostgreSQL restore attempted but no dump found!" 1>&2
    echo "$OPENSHIFT_DATA_DIR/postgresql_dump_snapshot.gz does not exist" 1>&2
fi
