#!/bin/bash

source "/etc/openshift/node.conf"

# Constants.
SERVICE_NAME=cron
CART_NAME=cron
CART_VERSION=1.4
CART_DIRNAME=${CART_NAME}-$CART_VERSION
CART_INSTALL_DIR=${CARTRIDGE_BASE_PATH}
CART_INFO_DIR=$CART_INSTALL_DIR/embedded/$CART_DIRNAME/info
CART_DIR=${CART_DIR:-$CART_INSTALL_DIR}

function log_message() {
   msg=${1-""}
   [ -z "$msg" ]  &&  return 0
   logger -i -s "user-cron-jobs" -p user.info "`date`: $msg"
}


#
# main():
#

# Ensure arguments.
if ! [ $# -eq 1 ]; then
    freqs=$(cat $CART_INFO_DIR/configuration/frequencies | tr '\n' '|')
    echo "Usage: $0 <${freqs%?}>"
    exit 22
fi

freq=$1

# Import Environment Variables
for f in ~/.env/*; do
    . $f
done

source "$CART_INFO_DIR/configuration/limits"

# First up check if the cron jobs are enabled.
CART_INSTANCE_DIR="$OPENSHIFT_HOMEDIR/$CART_DIRNAME"
if [ ! -f $CART_INSTANCE_DIR/run/jobs.enabled ]; then
   # Jobs are not enabled - just exit.
   exit 0
fi

log_message ":START: $freq cron run for openshift user '$OPENSHIFT_GEAR_UUID'"

# Run all the scripts in the $freq directory if it exists.
SCRIPTS_DIR="$OPENSHIFT_REPO_DIR/.openshift/cron/$freq"
if [ -d "$SCRIPTS_DIR" ]; then
   # Run all scripts in the scripts directory serially.
   executor="run-parts"
   [ -n "$MAX_RUN_TIME" ]  &&  executor="timeout $MAX_RUN_TIME run-parts"

   (
      flock -e -n 9
      status=$?

      if [ 0 -ne $status ]; then 
         log_message ":SKIPPED: $freq cron run for openshift user '$OPENSHIFT_GEAR_UUID'"
         exit 1
      fi

      if [ -f "$CART_INSTANCE_DIR/log/cron.$freq.log" ]; then
         mv -f "$CART_INSTANCE_DIR/log/cron.$freq.log" "$CART_INSTANCE_DIR/log/cron.$freq.log.1"
      fi

      separator=$(seq -s_ 75 | tr -d '[:digit:]')
      {
         echo $separator
         echo "`date`: START $freq cron run"
         echo $separator 

         #  Use run-parts - gives us jobs.{deny,allow} and whitelists.
         $executor "$SCRIPTS_DIR"
         status=$?
         if [ 124 -eq $status ]; then
            wmsg="Warning: $freq cron run terminated as it exceeded max run time"
            log_message "$wmsg [$MAX_RUN_TIME] for openshift user '$OPENSHIFT_GEAR_UUID'" > /dev/null 2>&1
            echo "$wmsg"
         fi

         echo $separator
         echo "`date`: END $freq cron run - status=$status"
         echo $separator
      } >> $CART_INSTANCE_DIR/log/cron.$freq.log 2>&1

   ) 9>~/app-root/runtime/.cron.$freq.lock
fi

log_message ":END: $freq cron run for openshift user '$OPENSHIFT_GEAR_UUID'"
exit 0
