#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source /etc/stickshift/stickshift-node.conf
CART_INFO_DIR=${CARTRIDGE_BASE_PATH}/embedded/mongodb-2.0/info
source ${CART_INFO_DIR}/lib/util


function die() {
   exitcode=${1:-0}
   tag=${2:-"ERROR"}
   msg=${3:-"Could not dump restore databases from dump"}

   echo 1>&2
   echo "!$tag! $msg" 1>&2
   echo 1>&2

   exit $exitcode

}  #  End of function  die.


function restore_from_mongodb_snapshot() {
   #  Work in a temporary directory (create and cd to it).
   mkdir -p /tmp/mongodump.$$
   pushd /tmp/mongodump.$$ > /dev/null

   #  Extract dump from the snapshot.
   if ! tar -zxf $OPENSHIFT_DATA_DIR/mongodb_dump_snapshot.tar.gz ; then
      popd > /dev/null
      /bin/rm -rf /tmp/mongodump.$$
      die 0 "WARNING" "Could not restore MongoDB databases - extract failed!"
   fi

   #  Restore from the "dump".
   creds="-u $OPENSHIFT_NOSQL_DB_USERNAME -p \"$OPENSHIFT_NOSQL_DB_PASSWORD\""
   if ! mongorestore -h $OPENSHIFT_NOSQL_DB_HOST $creds --directoryperdb --drop; then
      popd > /dev/null
      /bin/rm -rf /tmp/mongodump.$$
      die 0 "WARNING" "Could not restore MongoDB databases - mongorestore failed!"
   fi

   #  Restore previous dir and clean up temporary dir.
   popd > /dev/null
   /bin/rm -rf /tmp/mongodump.$$
   return 0

}  #  End of function  restore_from_mongodb_snapshot.



if [ ! -f $OPENSHIFT_DATA_DIR/mongodb_dump_snapshot.tar.gz ]; then
   echo "MongoDB restore attempted but no dump was found!" 1>&2
   die 0 "ERROR" "$OPENSHIFT_DATA_DIR/mongodb_dump_snapshot.tar.gz does not exist"
else
   start_mongodb_as_user
   restore_from_mongodb_snapshot
fi

exit 0

#