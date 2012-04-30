#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source /etc/stickshift/stickshift-node.conf
CART_INFO_DIR=${CARTRIDGE_BASE_PATH}/embedded/mysql-5.1/info
source ${CART_INFO_DIR}/lib/util

start_mysql_as_user 1>&2

dbhost=${OPENSHIFT_DB_GEAR_DNS:-$OPENSHIFT_DB_HOST}
echo $OPENSHIFT_DB_HOST > $OPENSHIFT_DATA_DIR/mysql_db_host
/usr/bin/mysqldump -h $dbhost -P $OPENSHIFT_DB_PORT -u $OPENSHIFT_DB_USERNAME --password="$OPENSHIFT_DB_PASSWORD" --all-databases --add-drop-table | /bin/gzip -v > $OPENSHIFT_DATA_DIR/mysql_dump_snapshot.gz

if [ ! ${PIPESTATUS[0]} -eq 0 ]
then
    echo 1>&2
    echo "WARNING!  Could not dump mysql!  Continuing anyway" 1>&2
    echo 1>&2
    /bin/rm -rf $OPENSHIFT_DATA_DIR/mysql_dump_snapshot.gz
fi
