#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

cartridge_type="nodejs-0.6"
cartridge_dir=$OPENSHIFT_HOMEDIR/$cartridge_type

function print_deprecation_warning() {
       cat <<DEPRECATED
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  The use of deplist.txt is being deprecated and will soon
  go away. For the short term, we will continue to support
  installing the Node modules specified in the deplist.txt
  file. But please be aware that this will soon go away.

  It is highly recommended that you use the package.json
  file to specify dependencies on other Node modules.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
DEPRECATED

}

function is_node_module_installed() {
    module_name=${1:-""}
    if [ -n "$module_name" ]; then
        pushd "$cartridge_dir" > /dev/null
        if [ -d $m ] ; then
            popd
            return 0
        fi
        popd
    fi

    return 1
}

gear_tmpdir="${cartridge_dir}/tmp/"
if [ -d "${gear_tmpdir}saved.node_modules" ]; then
   node_modules_dir="${OPENSHIFT_REPO_DIR}node_modules"
   mv "$node_modules_dir" "$gear_tmpdir"
   mv "${gear_tmpdir}/saved.node_modules" "$node_modules_dir"
   (shopt -s dotglob; mv -f "${gear_tmpdir}"node_modules/* "$node_modules_dir")
   rm -rf "${gear_tmpdir}"node_modules
fi

if [ -f "${OPENSHIFT_REPO_DIR}/.openshift/markers/force_clean_build" ]; then
    echo ".openshift/markers/force_clean_build found!  Recreating npm modules" 1>&2
    rm -rf "${cartridge_dir}"/node_modules/*
    rm -rf "${OPENSHIFT_HOMEDIR}"/.npm/*
    rm -rf "${OPENSHIFT_REPO_DIR}"node_modules/*
fi

#  Newer versions of Node set tmp to $HOME/tmp, so change tmpdir to /tmp.
npm config set tmp /tmp

if [ -f "${OPENSHIFT_REPO_DIR}"/deplist.txt ]; then
    mods=$(perl -ne 'print if /^\s*[^#\s]/' "${OPENSHIFT_REPO_DIR}"/deplist.txt)
    [ -n "$mods" ]  &&  print_deprecation_warning
    for m in $mods; do
        echo "Checking npm module: $m"
        echo
        if is_node_module_installed "$m"; then
            (cd "${cartridge_dir}"; npm update "$m")
        else
            (cd "${cartridge_dir}"; npm install "$m")
        fi
    done
fi

if [ -f "${OPENSHIFT_REPO_DIR}"/package.json ]; then
    (cd "${OPENSHIFT_REPO_DIR}"; npm install -d)
fi

# Run user build
user_build.sh
