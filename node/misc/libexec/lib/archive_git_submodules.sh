#!/bin/bash
git_dir=$1
target_dir=$2

# if GIT_DIR is set we need to unset it
[ ! -z "${GIT_DIR+xxx}" ] && unset GIT_DIR
set -xe;

pushd ${OPENSHIFT_TMP_DIR} > /dev/null
    git clone $git_dir git_cache

    pushd git_cache > /dev/null
        # initialize submodules and pull down source
        git submodule update --init --recursive

        # archive and copy the submodules
        git submodule foreach --recursive "git archive --format=tar HEAD | (cd $target_dir/\$name && tar --warning=no-timestamp -xf -)"

    popd > /dev/null
popd > /dev/null