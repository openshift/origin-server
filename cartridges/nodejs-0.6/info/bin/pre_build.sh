#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

rm -rf ${OPENSHIFT_GEAR_DIR}tmp/{node_modules,saved.node_modules}

# If the node_modules/ directory exists, then "stash" it away for redeploy.
node_modules_dir="${OPENSHIFT_REPO_DIR}node_modules"
if [ -d "$node_modules_dir" ]; then
  echo 'Saving away previously installed Node modules'
  mv "$node_modules_dir" "${OPENSHIFT_GEAR_DIR}tmp/saved.node_modules"
  mkdir "$node_modules_dir"
fi

redeploy_repo_dir.sh

user_pre_build.sh
