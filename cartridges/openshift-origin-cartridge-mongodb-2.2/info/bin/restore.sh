#!/bin/bash
cartridge_type="mongodb-2.2"

HAVE_MONGODB_221_RC1=""

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
   tag=${2:-"ERROR"}
   msg=${3:-"Could not dump restore databases from dump"}

   echo 1>&2
   echo "!$tag! $msg" 1>&2
   echo 1>&2

   exit $exitcode

}  #  End of function  die.


function start_mongod_without_auth() {
   $CART_INFO_DIR/bin/app_ctl.sh stop  ||  :
   $CART_INFO_DIR/bin/app_ctl.sh start-noauth

}  #  End of function  start_mongod_without_auth.


function restart_mongod_with_auth() {
    $CART_INFO_DIR/bin/app_ctl.sh stop  ||  :
    start_database_as_user

}  #  End of function  restart_mongod_with_auth.


function print_mongo_jira_warnings() {
   echo "
============================================================================
WARNING: You may have possibly encountered the mongorestore bugs related to
         MongoDB JIRA issues 7181, 7262 and 7104. We tried working around
         some these issues. You will need to manually workaround the
         remaining problems prior to proceeding. For more details, see: 
             https://jira.mongodb.org/browse/SERVER-7181
             https://jira.mongodb.org/browse/SERVER-7262
             https://jira.mongodb.org/browse/SERVER-7104
============================================================================
" 1>&2

}  #  End of function  print_mongo_jira_warnings.


function restore_from_mongodb_snapshot() {
   #  Work in a temporary directory (create and cd to it).
   umask 077
   dumpdir=$(mktemp -d /tmp/mongodumpXXXXXXXX)
   [ $? -eq 0 ] || die 0 "ERROR" "Failed to create working directory."
   pushd $dumpdir > /dev/null

   #  Extract dump from the snapshot.
   if ! tar -zxf $OPENSHIFT_DATA_DIR/mongodb_dump_snapshot.tar.gz ; then
      popd > /dev/null
      /bin/rm -rf $dumpdir
      restart_mongod_with_auth
      die 0 "WARNING" "Could not restore MongoDB databases - extract failed!"
   fi

   #  Restore from the "dump".
   creds="-u $OPENSHIFT_MONGODB_DB_USERNAME         \
          -p \"$OPENSHIFT_MONGODB_DB_PASSWORD\" "

   #  FIXME: Temporarily commented out auth due to mongo issue w/ restore.
   #        See  https://jira.mongodb.org/browse/SERVER-7262 for details.
   [ -z "$HAVE_MONGODB_221_RC1" ]  &&  creds=""

   if ! mongorestore -h $OPENSHIFT_MONGODB_DB_HOST              \
                     --port $OPENSHIFT_MONGODB_DB_PORT $creds   \
                     --directoryperdb --drop  1>&2; then
       print_mongo_jira_warnings
       popd > /dev/null
       /bin/rm -rf $dumpdir
       restart_mongod_with_auth
       die 0 "WARNING" "Could not restore MongoDB databases - mongorestore failed!"
   fi


   #  Restore previous dir and clean up temporary dir.
   popd > /dev/null
   /bin/rm -rf $dumpdir
   return 0

}  #  End of function  restore_from_mongodb_snapshot.



if [ ! -f $OPENSHIFT_DATA_DIR/mongodb_dump_snapshot.tar.gz ]; then
   echo "MongoDB restore attempted but no dump was found!" 1>&2
   die 0 "ERROR" "$OPENSHIFT_DATA_DIR/mongodb_dump_snapshot.tar.gz does not exist"
else
   #  FIXME: Temporarily modified due to mongo issue w/ restore.
   #        See  https://jira.mongodb.org/browse/SERVER-7262 for details.
   #  Need to start the server w/ noauth.
   start_mongod_without_auth
   restore_from_mongodb_snapshot
   restart_mongod_with_auth

   #  Use the commented code below (in place of the above workaround) once we
   #  have MONGODB 2.2.1 RC1 installed on OpenShift.
   #
   #  if [ -n "$HAVE_MONGODB_221_RC1" ]; then
   #     start_database_as_user
   #     restore_from_mongodb_snapshot
   #  fi
fi

exit 0

#
