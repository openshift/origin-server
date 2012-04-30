#!/bin/bash

source "/etc/stickshift/stickshift-node.conf"

# Control application's embedded job scheduling service (cron)
SERVICE_NAME=cron
CART_NAME=cron
CART_VERSION=1.4
CART_DIRNAME=${CART_NAME}-$CART_VERSION
CART_INSTALL_DIR=${CARTRIDGE_BASE_PATH}
CART_INFO_DIR=$CART_INSTALL_DIR/embedded/$CART_DIRNAME/info

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
      echo "$SERVICE_NAME scheduling service is enabled" 1>&2
   else
      echo "$SERVICE_NAME scheduling service is disabled" 1>&2
   fi

}  #  End of function  _cronjobs_status.


function _cronjobs_enable() {
   if _are_cronjobs_enabled; then
      echo "$SERVICE_NAME scheduling service is already enabled" 1>&2
   else
      touch "$CART_INSTANCE_DIR/run/jobs.enabled"
   fi

}  #  End of function  _cronjobs_enable.


function _cronjobs_disable() {
   if _are_cronjobs_enabled; then
      rm -f $CART_INSTANCE_DIR/run/jobs.enabled
   else
      echo "$SERVICE_NAME scheduling service is already disabled" 1>&2
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

# Cartridge instance dir and control script name.
CART_INSTANCE_DIR="$OPENSHIFT_HOMEDIR/$CART_DIRNAME"
CTL_SCRIPT="$CART_INSTANCE_DIR/${OPENSHIFT_GEAR_NAME}_${CART_NAME}_ctl.sh"
source ${CART_INFO_DIR}/lib/util

#  Ensure logged in as user.
if whoami | grep -q root
then
    echo 1>&2
    echo "Please don't run script as root, try:" 1>&2
    echo "runuser --shell /bin/sh $OPENSHIFT_GEAR_UUID $CTL_SCRIPT" 1>&2
    echo 2>&1
    exit 15
fi

case "$1" in
   enable|start)      _cronjobs_enable   ;;
   disable|stop)      _cronjobs_disable  ;;
   reenable|restart)  _cronjobs_reenable ;;
   status)            _cronjobs_status   ;;
esac

