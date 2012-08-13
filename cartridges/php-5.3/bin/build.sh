#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

if [ -f "${OPENSHIFT_REPO_DIR}/.openshift/markers/force_clean_build" ]
then
    echo ".openshift/markers/force_clean_build found!  Recreating pear libs" 1>&2
    rm -rf "${OPENSHIFT_GEAR_DIR}"/phplib/pear/*
    mkdir -p "${OPENSHIFT_GEAR_DIR}"/phplib/pear/{docs,ext,php,cache,cfg,data,download,temp,tests,www}
    pear -c ~/.pearrc config-set php_ini "${OPENSHIFT_GEAR_DIR}/conf/php.ini"
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
        else
            pear install --alldeps "$f"
        fi
    done
fi

# Run user build
user_build.sh