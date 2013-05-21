#!/bin/bash

#
# Archive files from a git module to another directory including the git
# submodules if present
#
function print_help {
    echo "Usage: $0 src_dir dest_dir"
    exit 1
}

[ $# -eq 2 ] || print_help

src_dir="$1"
dest_dir="$2"

function extract_submodules {
    # if GIT_DIR is set we need to unset it
    [ ! -z "${GIT_DIR+xxx}" ] && unset GIT_DIR

    # explode tree into a tmp dir
    tmp_dir=${OPENSHIFT_TMP_DIR}
    [ -e ${tmp_dir} ] || mkdir ${tmp_dir}
    submodule_tmp_dir=${tmp_dir}/submodules
    submodule_tmp_dir_length=`expr length $submodule_tmp_dir`

    pushd ${tmp_dir} > /dev/null
        [ -e ${submodule_tmp_dir} ] && rm -rf ${submodule_tmp_dir}
        git clone ${full_src_dir} submodules

        pushd ${submodule_tmp_dir} > /dev/null
            # initialize submodules and pull down source
            git submodule update --init --recursive

            # archive and copy the submodules
            git submodule foreach --recursive "git archive --format=tar HEAD | (cd ${dest_dir}/\${PWD:$submodule_tmp_dir_length} && tar --warning=no-timestamp -xf -)"
        popd > /dev/null
    popd > /dev/null
    rm -rf ${submodule_tmp_dir}
}

pushd ${src_dir} > /dev/null
full_src_dir=`pwd`

# archive and copy the main module
git archive --format=tar HEAD | (cd ${dest_dir} && tar --warning=no-timestamp -xf -)

# if a .gitmodules file exists we need to explode the whole tree and extract
# the submoules
[ -f ${dest_dir}/.gitmodules ] && extract_submodules

popd > /dev/null
