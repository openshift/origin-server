#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

cart_instance_dir=$OPENSHIFT_HOMEDIR/ruby-1.9

if [ -z "$BUILD_NUMBER" ]
then
  USED_BUNDLER=false
  if [ -d $cart_instance_dir/tmp/.bundle ]
  then
    USED_BUNDLER=true
  fi

  if $USED_BUNDLER
  then
    echo 'Restoring previously bundled RubyGems (note: you can commit .openshift/markers/force_clean_build at the root of your repo to force a clean bundle)'
    mv $cart_instance_dir/tmp/.bundle ${OPENSHIFT_REPO_DIR}
    if [ -d ${OPENSHIFT_REPO_DIR}vendor ]
    then
      mv $cart_instance_dir/tmp/vendor/bundle ${OPENSHIFT_REPO_DIR}vendor/
    else
      mv $cart_instance_dir/tmp/vendor ${OPENSHIFT_REPO_DIR}
    fi
    rm -rf $cart_instance_dir/tmp/.bundle $cart_instance_dir/tmp/vendor
  fi
  
  # If .bundle isn't currently committed and a Gemfile is then bundle install
  if [ -f ${OPENSHIFT_REPO_DIR}/Gemfile ]
  then
      if ! git show master:.bundle > /dev/null 2>&1
      then
          echo "Bundling RubyGems based on Gemfile/Gemfile.lock to repo/vendor/bundle with 'bundle install --deployment'"
          SAVED_GIT_DIR=$GIT_DIR
          unset GIT_DIR
          pushd ${OPENSHIFT_REPO_DIR} > /dev/null
          /usr/bin/scl enable ruby193 "bundle install --deployment"
          popd > /dev/null
          export GIT_DIR=$SAVED_GIT_DIR
      fi
      echo "Precompiling with 'bundle exec rake assets:precompile'"
      pushd ${OPENSHIFT_REPO_DIR} > /dev/null
      /usr/bin/scl enable ruby193 "bundle exec rake assets:precompile" 2>/dev/null
      popd > /dev/null
  fi

fi

/usr/bin/scl enable ruby193 "user_build.sh"
