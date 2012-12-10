#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

cartridge_type="php-5.3"
OPENSHIFT_PHP_DIR=$OPENSHIFT_HOMEDIR/$cartridge_type/

if [ -f "${OPENSHIFT_REPO_DIR}/.openshift/markers/force_clean_build" ]
then
    echo ".openshift/markers/force_clean_build found!  Recreating pear libs" 1>&2
    rm -rf "${OPENSHIFT_PHP_DIR}"/phplib/pear/*
    mkdir -p "${OPENSHIFT_PHP_DIR}"/phplib/pear/{docs,ext,php,cache,cfg,data,download,temp,tests,www}
fi

if [ -f ${OPENSHIFT_REPO_DIR}deplist.txt ]
then
    for f in $(cat ${OPENSHIFT_REPO_DIR}deplist.txt)
    do
        echo "Checking pear: $f"
        echo
        if pear list "$f" > /dev/null
        then
            pear upgrade "$f"
        elif ! ( php -c "${OPENSHIFT_PHP_DIR}"/conf -m | grep -q \^`basename "$f"`\$ )
        then
            pear install --alldeps "$f"
        else
            echo "Extension already installed in the system: $f"
        fi
    done
fi

# Run user build
user_build.sh
