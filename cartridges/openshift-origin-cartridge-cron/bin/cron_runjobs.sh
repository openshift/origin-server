#!/bin/bash

source "/usr/lib/openshift/cartridge_sdk/bash/sdk"

# source OpenShift environment variable into context
function load_env {
    [ -z "$1" ] && return 1

    if [ -d "$1" ]
    then
      for f in ${1}/*
      do
        load_env $f
      done
      return
    fi

    [ -f "$1" ] || return 0
    [[ "$1" =~ .*\.rpmnew$ ]] && return 0

    local contents=$(< $1)
    local key=$(basename $1)
    export $key=$(< $1)
}

for f in ~/.env/* ~/.env/user_vars/* ~/*/env/*
do
    load_env $f
done

export PATH=$(build_path)
export LD_LIBRARY_PATH=$(build_ld_library_path)

CART_CONF_DIR=$OPENSHIFT_CRON_DIR/configuration

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

[[ -f /etc/openshift/cron/limits ]] && source /etc/openshift/cron/limits

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
   if [ -n "$MAX_RUN_TIME" ]; then
     # TODO: use signal -s 1 --kill-after=$KILL_AFTER_TIME" when available
     executor="timeout -s 9 $MAX_RUN_TIME run-parts"
   fi

   (
      flock -e -n 9
      status=$?

      (
          if [ 0 -ne $status ]; then
              log_message ":SKIPPED: $freq cron run for openshift user '$OPENSHIFT_GEAR_UUID'"
              exit 1
          fi

          if [ -f "$OPENSHIFT_CRON_DIR/log/cron.$freq.log" ]; then
              mv -f "$OPENSHIFT_CRON_DIR/log/cron.$freq.log" "$OPENSHIFT_CRON_DIR/log/cron.$freq.log.1"
          fi

          LOGPIPE=${OPENSHIFT_HOMEDIR}/app-root/runtime/logshifter-cron-${freq}
          rm -f $LOGPIPE && mkfifo $LOGPIPE
          /usr/bin/logshifter -tag cron_${freq} < $LOGPIPE &

          separator=$(seq -s_ 75 | tr -d '[:digit:]')
          {
              echo $separator
              echo "`date`: START $freq cron run"
              echo $separator

              #  Use run-parts - gives us jobs.{deny,allow} and whitelists.
              $executor "$SCRIPTS_DIR"
              status=$?
              if [ 124 -eq $status -o 137 -eq $status ]; then
                  wmsg="Warning: $freq cron run terminated as it exceeded max run time"
                  log_message "$wmsg [$MAX_RUN_TIME] for openshift user '$OPENSHIFT_GEAR_UUID'" > /dev/null 2>&1
                  echo "$wmsg"
              fi

              echo $separator
              echo "`date`: END $freq cron run - status=$status"
              echo $separator
          } &> $LOGPIPE

      ) 9>&-

   ) 9>${OPENSHIFT_HOMEDIR}app-root/runtime/.cron.$freq.lock
fi

log_message ":END: $freq cron run for openshift user '$OPENSHIFT_GEAR_UUID'"
exit 0
