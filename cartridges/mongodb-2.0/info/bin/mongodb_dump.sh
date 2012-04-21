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
   tag=${2:-"WARNING"}
   msg=${3:-"Could not dump MongoDB databases! Continuing anyway ..."}

   echo 1>&2
   echo "!$tag! $msg" 1>&2
   echo 1>&2

   exit $exitcode

}  #  End of function  die.


function create_mongodb_snapshot() {
   #  Work in a temporary directory (create and cd to it).
   mkdir -p /tmp/mongodump.$$
   pushd /tmp/mongodump.$$ > /dev/null

   #  Take a "dump".
   creds="-u $OPENSHIFT_NOSQL_DB_USERNAME -p \"$OPENSHIFT_NOSQL_DB_PASSWORD\""
   if mongodump -h $OPENSHIFT_NOSQL_DB_HOST $creds --directoryperdb > /dev/null 2>&1; then
      #  Dump ok - now create a gzipped tarball.
      if tar -zcf $OPENSHIFT_DATA_DIR/mongodb_dump_snapshot.tar.gz . ; then
         #  Created dump snapshot - restore previous dir and remove temp dir.
         popd > /dev/null
         /bin/rm -rf /tmp/mongodump.$$
         return 0
      else
         err_details="- snapshot failed"
      fi
   else
      err_details="- mongodump failed"
   fi

   #  Failed to dump/gzip - log error and exit.
   popd > /dev/null
   /bin/rm -rf /tmp/mongodump.$$
   /bin/rm -f  $OPENSHIFT_DATA_DIR/mongodb_dump_snapshot.tar.gz
   die 0 "WARNING" "Could not dump MongoDB databases ${err_details}!"

}  #  End of function  create_mongodb_snapshot.


start_mongodb_as_user
create_mongodb_snapshot
exit 0
