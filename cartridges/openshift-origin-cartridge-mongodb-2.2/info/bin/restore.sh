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
   tag=${2:-"ERROR"}
   msg=${3:-"Could not dump restore databases from dump"}

   echo 1>&2
   echo "!$tag! $msg" 1>&2
   echo 1>&2

   exit $exitcode

}  #  End of function  die.


function print_jira_7181_warning() {
   echo "
============================================================================
WARNING: Ignoring errors ... Please make sure the errors are related to a
         mongorestore issue with auth enabled. Otherwise fix the errors.
         See:  https://jira.mongodb.org/browse/SERVER-7181  for details.
============================================================================
"

}  #  End of function  print_jira_7181_warning.


function restore_databases_individually() {
   #  Temporary fix to handle mongodb bug w/ restore - see
   #     https://jira.mongodb.org/browse/SERVER-7262
   #  for details. Remove once we have MONGODB 2.2 RC1 version.

   dumpdir=${1:-"./"}
   pushd "$dumpdir" > /dev/null

   if [ ! -d "dump" ]; then
       echo "MongoDB restore attempted but no dump directory was found!" 1>&2
       popd  > /dev/null
       return 0
   fi

   #  Operate on the databases individually.
   for dbname in `ls dump/`; do
       if ! mongorestore -h $OPENSHIFT_MONGODB_DB_HOST $creds --directoryperdb --drop -d $dbname dump/$dbname; then
           if [ -f "dump/$dbname/system.users.bson" ]; then
               #  mongorestore has issues on a server w/ auth enabled.
               #  See: https://jira.mongodb.org/browse/SERVER-7181 for details.
               #  Ignore errors if there's a users collection.
               print_jira_7181_warning
           else
               popd > /dev/null
	       /bin/rm -rf /tmp/mongodump.$$
               die 71 "ERROR" "Error restoring MongoDB database $dbname"
           fi
       fi
   done

   popd  > /dev/null

}  #  End of function  restore_databases_individually.


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
   creds="-u $OPENSHIFT_MONGODB_DB_USERNAME -p \"$OPENSHIFT_MONGODB_DB_PASSWORD\" --port $OPENSHIFT_MONGODB_DB_PORT"

   #  FIXME: Temporary commented out due to mongo issue w/ restore.
   #        See  https://jira.mongodb.org/browse/SERVER-7262 for details.
   #  Use the else part once we have MONGODB 2.2 RC1 version in OpenShift.
   if [ -z "$HAVE_MONGODB_22_RC1" ]; then
       restore_databases_individually "/tmp/mongodump.$$"
   else
       if ! mongorestore -h $OPENSHIFT_MONGODB_DB_HOST $creds --directoryperdb --drop; then
           popd > /dev/null
           /bin/rm -rf /tmp/mongodump.$$
           die 0 "WARNING" "Could not restore MongoDB databases - mongorestore failed!"
        fi
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
   start_database_as_user
   restore_from_mongodb_snapshot
fi

exit 0

#
