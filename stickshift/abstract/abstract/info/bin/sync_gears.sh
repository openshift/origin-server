#!/bin/bash

# Source the application environment
for f in ~/.env/*
do
    [ -f "$f" ] && source "$f"
done

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Set the sync source base dir
CART_PATH=$(cd -P $(dirname "$0")/../.. && pwd)
SYNC_BASE_DIR="$OPENSHIFT_HOMEDIR/$(basename "$CART_PATH")"

# Defines the default pre sync actions, taking into account
# the hot_deploy marker.
function set_default_pre_actions {
  if hot_deploy_marker_is_present; then
    echo "Application will not be stopped during gear sync to to presence of hot_deploy marker"
    OPENSHIFT_SYNC_GEARS_PRE=()
  else
    OPENSHIFT_SYNC_GEARS_PRE=('ctl_all stop')
  fi
}

# Defines the default post sync actions, taking into account
# the hot_deploy marker.
function set_default_post_actions {
  if hot_deploy_marker_is_present; then
    echo "Application will not be restarted during gear sync due to presence of hot_deploy marker"
    OPENSHIFT_SYNC_GEARS_POST=('deploy.sh' 'post_deploy.sh')
  else
    OPENSHIFT_SYNC_GEARS_POST=('deploy.sh' 'ctl_all start' 'post_deploy.sh')
  fi
}

# Defaults for sync-gears.  Override these in .env from the configure script
[ -z "$OPENSHIFT_SYNC_GEARS_DIRS" ] && OPENSHIFT_SYNC_GEARS_DIRS=( "repo" "node_modules" "virtenv" "../.m2" ".openshift" "deployments" "perl5lib" "phplib" )
[ -z "$OPENSHIFT_SYNC_GEARS_PRE" ] && set_default_pre_actions
[ -z "$OPENSHIFT_SYNC_GEARS_POST" ] && set_default_post_actions
declare -ax OPENSHIFT_SYNC_GEARS_DIRS OPENSHIFT_SYNC_GEARS_PRE OPENSHIFT_SYNC_GEARS_POST

rsynccmd="rsync -v --delete-after -az"
export RSYNC_RSH="ssh"

# Fix to get name of haproxy cartridge from environment
HAPROXY_CONF_DIR=$OPENSHIFT_HOMEDIR/haproxy-1.4/conf
HAPROXY_GEAR_REGISTRY=$HAPROXY_CONF_DIR/gear-registry.db

# Manage sync tasks in parallel
if [ -n "$1" ]; then
   GEARSET[0]="$1"
else
   GEARSET=($(< "${HAPROXY_GEAR_REGISTRY}"))
fi
STDOUTS=()   # Set of outputs
EXITCODES=() # Set of exit codes

for zinfo in "${GEARSET[@]}"
do
  zarr=(${zinfo//;/ })
  gear=${zarr[0]}
  arr=(${gear//:/ })
  sshcmd="ssh ${arr[0]}"
  echo "SSH_CMD: ${sshcmd}"
  output=$(mktemp "${SYNC_BASE_DIR}/tmp/sync_gears.output.XXXXXXXXXXXXXXXX")
  STDOUTS+=("$output")
  exitcode=$(mktemp "${SYNC_BASE_DIR}/tmp/sync_gears.exit.XXXXXXXXXXXXXXXX")
  EXITCODES+=("$exitcode")
  (
    (
      set -x -e
      echo "Syncing to gear: $gear @ " $(date)

      # Prepare remote gear for new content
      for rpccall in "${OPENSHIFT_SYNC_GEARS_PRE[@]}"
      do
        $sshcmd "$rpccall"
      done

      # Push content to remote gear
      for subd in "${OPENSHIFT_SYNC_GEARS_DIRS[@]}"
      do
        if [ -d "${SYNC_BASE_DIR}/${subd}" ]
        then
          $rsynccmd "${SYNC_BASE_DIR}/${subd}/" "${gear}/${subd}/"
        fi
      done

      # Post-sync calls & start
      for rpccall in "${OPENSHIFT_SYNC_GEARS_POST[@]}"
      do
        $sshcmd "$rpccall"
      done

    )
    echo $? > "$exitcode"
  ) >"$output" 2>&1 &
done
wait

# Serialize outputs and exit codes for easier debugging
exc=0
slen=${#STDOUTS[@]}
for (( i=0; i<${slen}; i++ ))
do
  cat "${STDOUTS[$i]}"
  pexc=$(cat "${EXITCODES[$i]}")
  echo "Exit code: $pexc"
  if [ "$pexc" != "0" ]; then
    exc=128   # TODO: instead? exc=$(($exc | $pexc))
  fi
  rm -f "${STDOUTS[$i]}" "${EXITCODES[$i]}"
done

exit $exc
