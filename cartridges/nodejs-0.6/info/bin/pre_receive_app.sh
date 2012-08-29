#!/bin/bash

# This hook is what drives the initial shutdown of the application prior to 
# applying incoming commits. Because it must respect the presence of the
# hot_deploy marker, this becomes a bit tricky as we must take into account
# the possibility that the marker is being added or removed during the
# commit, possibly for the first time. The stop should only occur if the
# marker is present and will remain present after the commit is applied.

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

# Stops the app (or not), taking into account the hot_deploy marker.
function stop_app () {
  # We ONLY want to disable this if the hot deploy marker will be present
  # following the commit application.
  stop_required=true


  # All our decisions will be based on these three states. It is
  # assumed that added/deleted are mutually exclusive states.
  hot_deploy_preexists=false
  hot_deploy_added=false
  hot_deploy_deleted=false


  # Check to see if the marker is already on disk
  if hot_deploy_marker_is_present; then
    hot_deploy_preexists=true
  fi


  # Peek into the inbound push and see if the marker state is being updated
  # in any notable way
  while read old_sha1 new_sha1 refname ; do
    # Detect the addition of the marker
    if commit_contains_file_with_status "$new_sha1" ".openshift/markers/hot_deploy" "A"; then
      hot_deploy_added=true
      break
    fi

    # Detect the deletion of the marker
    if commit_contains_file_with_status "$new_sha1" ".openshift/markers/hot_deploy" "D"; then
      hot_deploy_deleted=true
      break
    fi
  done

  # Debug use
  #echo "hot_deploy_added=${hot_deploy_added}"
  #echo "hot_deploy_deleted=${hot_deploy_deleted}"
  #echo "hot_deploy_preexists=${hot_deploy_preexists}"

  # There are only two cases which should cause the stop to be disabled:
  # 1. The marker is being added and was not present in the first place
  if ! $hot_deploy_preexists && $hot_deploy_added; then
    echo "Will add new hot deploy marker"
    stop_required=true
  fi

  # 2. The marker is already present and is not modified with this commit
  if $hot_deploy_preexists && ! $hot_deploy_added && ! $hot_deploy_deleted; then
    echo "Existing hot deploy marker will remain unchanged"
    stop_required=false
  fi


  # And finally...
  if $stop_required; then
    stop_app.sh
  else
    echo "App will not be stopped due to presence of hot_deploy marker"
  fi
}

# Import environment variables
for f in ~/.env/*
do
    . $f
done

# Only handle app stopping here if hooks are enabled and if this
# Jenkins is not embedded
if [ -z $OPENSHIFT_SKIP_GIT_HOOKS ]
then
    if [ -z "$OPENSHIFT_CI_TYPE" ] || [ -z "$JENKINS_URL" ]
    then
        stop_app
    fi
fi
