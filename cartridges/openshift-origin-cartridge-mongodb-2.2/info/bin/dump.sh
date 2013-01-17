#!/bin/bash
cartridge_type="mongodb-2.2"

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

#  FIXME: Temporary fix for bugz 856487 - Can't add mongodb-2.0 to a ruby1.9 app
#         This needs to be removed once we change how we hande sclized versions
#         of packages.
unset LD_LIBRARY_PATH

source /etc/openshift/node.conf
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util
CART_INFO_DIR=${CARTRIDGE_BASE_PATH}/$cartridge_type/info
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
   umask 077
   dumpdir = $(mktemp -d mongodumpXXXXXXXX)
   [ $? -eq 0 ] || die 0 "ERROR" "Failed to create working directory."
   pushd $dumpdir > /dev/null

   #  Take a "dump".
   creds="-u $OPENSHIFT_MONGODB_DB_USERNAME -p \"$OPENSHIFT_MONGODB_DB_PASSWORD\" --port $OPENSHIFT_MONGODB_DB_PORT"
   if mongodump -h $OPENSHIFT_MONGODB_DB_HOST $creds --directoryperdb > /dev/null 2>&1; then
      #  Dump ok - now create a gzipped tarball.
      if tar -zcf $OPENSHIFT_DATA_DIR/mongodb_dump_snapshot.tar.gz . ; then
         #  Created dump snapshot - restore previous dir and remove temp dir.
         popd > /dev/null
         /bin/rm -rf $dumpdir
         return 0
      else
         err_details="- snapshot failed"
      fi
   else
      err_details="- mongodump failed"
   fi

   #  Failed to dump/gzip - log error and exit.
   popd > /dev/null
   /bin/rm -rf $dumpdir
   /bin/rm -f  $OPENSHIFT_DATA_DIR/mongodb_dump_snapshot.tar.gz
   die 0 "WARNING" "Could not dump MongoDB databases ${err_details}!"

}  #  End of function  create_mongodb_snapshot.


start_database_as_user 1>&2
create_mongodb_snapshot
exit 0
