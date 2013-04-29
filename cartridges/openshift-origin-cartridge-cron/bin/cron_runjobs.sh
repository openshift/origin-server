#!/bin/bash

# source OpenShift environment variable into context
function load_env {
    [ -z "$1" ] && return 1
    [ -f "$1" ] || return 0

    local contents=$(< $1)
    if [[ $contents =~ ^export\ .* ]]
    then
      source $1
    else
      local key=$(basename $1)
      export $key=$(< $1)
    fi
}

for f in ~/.env/* ~/.env/.uservars/* ~/*/env/*
do
    load_env $f
done

CART_CONF_DIR=$OPENSHIFT_CRON_DIR/versions/$OPENSHIFT_CRON_VERSION/configuration

function log_message() {
   msg=${1-""}
   [ -z "$msg" ]  &&  return 0
   logger -i -s "user-cron-jobs" -p user.info "`date`: $msg"
}

# Ensure arguments.
if ! [ $# -eq 1 ]; then
    freqs=$(cat $CART_CONF_DIR/frequencies | tr '\n' '|')
    echo "Usage: $0 <${freqs%?}>"
    exit 22
fi

freq=$1
source "$CART_CONF_DIR/limits"

# First up check if the cron jobs are enabled.
if [ ! -f $OPENSHIFT_CRON_DIR/run/jobs.enabled ]; then
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

      if [ -f "$OPENSHIFT_CRON_DIR/logs/cron.$freq.log" ]; then
         mv -f "$OPENSHIFT_CRON_DIR/logs/cron.$freq.log" "$OPENSHIFT_CRON_DIR/logs/cron.$freq.log.1"
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
      } >> $OPENSHIFT_CRON_DIR/logs/cron.$freq.log 2>&1

   ) 9>${OPENSHIFT_HOMEDIR}app-root/runtime/.cron.$freq.lock
fi

log_message ":END: $freq cron run for openshift user '$OPENSHIFT_GEAR_UUID'"
exit 0
