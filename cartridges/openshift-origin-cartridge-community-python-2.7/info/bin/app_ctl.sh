#!/bin/bash

#  Exit on errors.
set -e

#  "Globals" + load/source config + utility functions.
cartridge_type='python-2.7'
source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util
source ${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/lib/util

# Import Environment Variables
source ${CARTRIDGE_BASE_PATH}/${cartridge_type}/info/bin/source_env_vars


if [ $# -ne 1 ]; then
   echo "Usage: \$0 [start|restart|graceful|graceful-stop|stop]"
   exit 1
fi


function start_community_cart() {
   _state=`get_app_state`
   if [ -f $OPENSHIFT_HOMEDIR/$cartridge_type/run/stop_lock  -o  idle = "$_state" ]; then
       echo "Application is explicitly stopped!  Use 'rhc app start -a ${OPENSHIFT_APP_NAME}' to start back up." 1>&2
       return 0
   fi

   set_app_state started

   src_user_hook "pre_start_$cartridge_type"
   run_cartridge_script_as_user "$cartridge_type" "control" "start"
   run_user_hook "post_start_$cartridge_type"

}  #  End of function  start_community_cart.


function stop_community_cart() {
   set_app_state stopped

   src_user_hook "pre_stop_$cartridge_type"
   run_cartridge_script_as_user "$cartridge_type" "control" "stop"
   run_user_hook "post_stop_$cartridge_type"

}  #  End of function  stop_community_cart.


function restart_community_cart() {
   stop_community_cart
   start_community_cart

}  #  End of function  restart_community_cart.



function reload_community_cart() {
   ctl_args=${1:-"reload"}

   # Ensure app's not stopped/idle.
   _state=`get_app_state`
   if [ -f $OPENSHIFT_HOMEDIR/$cartridge_type/run/stop_lock -o idle = "$_state" ]; then
      echo "Application is explicitly stopped!  Use 'rhc app start -a ${OPENSHIFT_GEAR_NAME}' to start back up." 1>&2
      return 0
   fi

   run_cartridge_script_as_user "$cartridge_type" "control" "$ctl_args"

}  #  End of function  reload_community_cart.


validate_run_as_user

. app_ctl_pre.sh

case "$1" in
   start)               start_community_cart                  ;;
   graceful-stop|stop)  stop_community_cart                   ;;
   restart)             restart_community_cart                ;;
   reload|graceful)     reload_community_cart "$1"            ;;
   status)              print_user_running_processes `id -u`  ;;
esac

