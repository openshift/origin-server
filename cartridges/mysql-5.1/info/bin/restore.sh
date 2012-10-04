#!/bin/bash
cartridge_type="mysql-5.1"

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done


if [ -f $OPENSHIFT_DATA_DIR/mysql_dump_snapshot.gz ]
then
    source /etc/openshift/node.conf
    source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util
    CART_INFO_DIR=${CARTRIDGE_BASE_PATH}/$cartridge_type/info
    source ${CART_INFO_DIR}/lib/util

    start_database_as_user

    dbhost=${OPENSHIFT_MYSQL_DB_GEAR_DNS:-$OPENSHIFT_MYSQL_DB_HOST}
    OLD_IP=$(/bin/cat $OPENSHIFT_DATA_DIR/mysql_db_host)
    NEW_IP=$(get_db_host_as_user)
    # Prep the mysql database
    (
        /bin/zcat $OPENSHIFT_DATA_DIR/mysql_dump_snapshot.gz
        echo ";"
        echo "UPDATE mysql.user SET Host='$NEW_IP' WHERE Host='$OLD_IP';"
        echo "UPDATE mysql.user SET Password=PASSWORD('$OPENSHIFT_MYSQL_DB_PASSWORD') WHERE User='$OPENSHIFT_MYSQL_DB_USERNAME';"
        echo "FLUSH PRIVILEGES;"
    ) | /usr/bin/mysql -h $dbhost -P $OPENSHIFT_MYSQL_DB_PORT -u $OPENSHIFT_MYSQL_DB_USERNAME --password="$OPENSHIFT_MYSQL_DB_PASSWORD"
    if [ ! ${PIPESTATUS[1]} -eq 0 ]
    then
        echo 1>&2
        echo "Error: Could not import MySQL Database!  Continuing..." 1>&2
        echo 1>&2
    fi
    ${CART_INFO_DIR}/bin/cleanup.sh

else
    echo "MySQL restore attempted but no dump found!" 1>&2
    echo "$OPENSHIFT_DATA_DIR/mysql_dump_snapshot.gz does not exist" 1>&2
fi
