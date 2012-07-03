#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

rm -rf ${OPENSHIFT_GEAR_DIR}tmp/.bundle ${OPENSHIFT_GEAR_DIR}tmp/vendor

# If the previous and current commits didn't upload .bundle and you have .bundle and vendor/bundle already deployed then store away for redeploy
# Also adding .openshift/markers/force_clean_build at the root of the repo will trigger a clean rebundle
if ! git show master:.openshift/markers/force_clean_build > /dev/null 2>&1 && ! git show master:.bundle > /dev/null 2>&1 && ! git show master~1:.bundle > /dev/null 2>&1 && [ -d ${OPENSHIFT_REPO_DIR}.bundle ] && [ -d ${OPENSHIFT_REPO_DIR}vendor/bundle ]
then
  echo 'Saving away previously bundled RubyGems'
  mv ${OPENSHIFT_REPO_DIR}.bundle ${OPENSHIFT_GEAR_DIR}tmp/
  mv ${OPENSHIFT_REPO_DIR}vendor ${OPENSHIFT_GEAR_DIR}tmp/
fi

redeploy_repo_dir.sh

user_pre_build.sh