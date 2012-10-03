#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

cart_instance_dir=$OPENSHIFT_HOMEDIR/ruby-1.9
ruby_tmp_dir=$cart_instance_dir/tmp

rm -rf ${ruby_tmp_dir}/.bundle ${ruby_tmp_dir}/vendor

# If the previous and current commits didn't upload .bundle and you have .bundle and vendor/bundle already deployed then store away for redeploy
# Also adding .openshift/markers/force_clean_build at the root of the repo will trigger a clean rebundle
if ! git show master:.openshift/markers/force_clean_build > /dev/null 2>&1 && ! git show master:.bundle > /dev/null 2>&1 && ! git show master~1:.bundle > /dev/null 2>&1 && [ -d ${OPENSHIFT_REPO_DIR}.bundle ] && [ -d ${OPENSHIFT_REPO_DIR}vendor/bundle ]
then
  echo 'Saving away previously bundled RubyGems'
  mv ${OPENSHIFT_REPO_DIR}.bundle ${ruby_tmp_dir}/
  mv ${OPENSHIFT_REPO_DIR}vendor ${ruby_tmp_dir}/
fi

redeploy_repo_dir.sh

/usr/bin/scl enable ruby193 "user_pre_build.sh"
