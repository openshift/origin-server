#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

VIRTENV="~/python-2.6/virtenv"

cart_instance_dir=$OPENSHIFT_HOMEDIR/python-2.6
if `echo $OPENSHIFT_GEAR_DNS | egrep -qe "\.rhcloud\.com"`
then 
    OPENSHIFT_PYTHON_MIRROR="-i http://mirror1.ops.rhcloud.com/mirror/python/web/simple"
fi

# Run when jenkins is not being used or run when inside a build
if [ -f "${OPENSHIFT_REPO_DIR}/.openshift/markers/force_clean_build" ]
then
    echo ".openshift/markers/force_clean_build found!  Recreating virtenv" 1>&2
    rm -rf $cart_instance_dir/virtenv/*
fi

if [ -f ${OPENSHIFT_REPO_DIR}setup.py ]
then
    echo "setup.py found.  Setting up virtualenv"
    cd $VIRTENV

    # Hack to fix symlink on rsync issue
    /bin/rm -f lib64
    virtualenv --system-site-packages $VIRTENV
    . ./bin/activate
	python ${OPENSHIFT_REPO_DIR}setup.py develop $OPENSHIFT_PYTHON_MIRROR
    virtualenv --relocatable $VIRTENV
fi

# Run build
user_build.sh
