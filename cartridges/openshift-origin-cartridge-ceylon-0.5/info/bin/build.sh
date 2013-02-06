#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

cartridge_type="ceylon-0.5"

if [ -f "${OPENSHIFT_REPO_DIR}/.openshift/action_hooks/pre_build_ceylon" ]
then
   echo "Sourcing pre_build_ceylon" 1>&2
   source ${OPENSHIFT_REPO_DIR}/.openshift/action_hooks/pre_build_ceylon
fi

JAVA_OPTS="-Dceylon.cache.repo=${CEYLON_USER_REPO}/cache"
JAVA_OPTS="$JAVA_OPTS -Dcom.redhat.ceylon.common.tool.terminal.width=9999" #do not wrap output
export JAVA_OPTS
export PRESERVE_JAVA_OPTS="true"

compile_files=`find ${OPENSHIFT_REPO_DIR}/source/ -name *\.ceylon -o -name *\.java`
printf "Compiling files:\n$compile_files\n"
${CEYLON_HOME}/bin/ceylon compile --out ${CEYLON_USER_REPO} ${compile_files}
        
# Run user build
user_build.sh
