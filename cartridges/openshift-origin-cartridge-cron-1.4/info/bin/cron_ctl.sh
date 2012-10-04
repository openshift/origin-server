#!/bin/bash -e

cartridge_type='cron-1.4'
source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Control application's embedded job scheduling service (cron)
CART_INFO_DIR=$CARTRIDGE_BASE_PATH/embedded/$cartridge_type/info

function _are_cronjobs_enabled() {
   [ -f $CART_INSTANCE_DIR/run/jobs.enabled ]  &&  return 0
   return 1

}  #  End of function  _are_cronjobs_enabled.


function _cronjobs_status() {
   if [ -d "$OPENSHIFT_REPO_DIR/.openshift/cron" ]; then
      njobs=0
      for freq in `cat $CART_INFO_DIR/configuration/frequencies`; do
         if [ -d "$OPENSHIFT_REPO_DIR/.openshift/cron/$freq" ]; then
            jobcnt=$(ls $OPENSHIFT_REPO_DIR/.openshift/cron/$freq | wc -l)
            njobs=$((njobs + jobcnt))
         fi
      done
      if test 0 -ge ${njobs:-0}; then
         echo "Application has no scheduled jobs" 1>&2
      fi
   else
      echo "Application has no scheduled jobs" 1>&2
      echo "   - Missing .openshift/cron/ directory." 1>&2
   fi

   if _are_cronjobs_enabled; then
      echo "cron scheduling service is enabled" 1>&2
   else
      echo "cron scheduling service is disabled" 1>&2
   fi

}  #  End of function  _cronjobs_status.


function _cronjobs_enable() {
    if _are_cronjobs_enabled; then
        src_user_hook pre_start_cron-1.4
        echo "cron scheduling service is already enabled" 1>&2
        run_user_hook post_start_cron-1.4
    else
        touch "$CART_INSTANCE_DIR/run/jobs.enabled"
    fi

}  #  End of function  _cronjobs_enable.


function _cronjobs_disable() {
    if _are_cronjobs_enabled; then
        src_user_hook pre_stop_cron-1.4
        rm -f $CART_INSTANCE_DIR/run/jobs.enabled
        run_user_hook post_stop_cron-1.4
    else
        echo "cron scheduling service is already disabled" 1>&2
    fi

}  #  End of function  _cronjobs_disable.


function _cronjobs_reenable() {
   _cronjobs_disable
   _cronjobs_enable

}  #  End of function  _cronjobs_reenable.


#
# main():
#
# Ensure arguments.
if ! [ $# -eq 1 ]; then
    echo "Usage: $0 [enable|reenable|disable|status|start|restart|stop]"
    exit 1
fi

# Import Environment Variables
for f in ~/.env/*; do
  . $f
done
translate_env_vars
validate_run_as_user

# Cartridge instance dir and control script name.
CART_INSTANCE_DIR="$OPENSHIFT_HOMEDIR/$cartridge_type"
CTL_SCRIPT="$CARTRIDGE_BASE_PATH/$cartridge_type/info/bin/app_ctl.sh"

case "$1" in
   enable|start)      _cronjobs_enable   ;;
   disable|stop)      _cronjobs_disable  ;;
   reenable|restart)  _cronjobs_reenable ;;
   status)            _cronjobs_status   ;;
esac

