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

ceylon_repos="--rep http://modules.ceylon-lang.org/test/"
ceylon_repos="${ceylon_repos} --rep ${CEYLON_USER_REPO}"
ceylon_repos="${ceylon_repos} --rep ${OPENSHIFT_REPO_DIR}.openshift/config/modules"

compile_files=`find ${OPENSHIFT_REPO_DIR}/source/ -name *\.ceylon -o -name *\.java`
printf "Compiling files:\n$compile_files\n"
${CEYLON_HOME}/bin/ceylon compile --src ${OPENSHIFT_REPO_DIR}/source --out ${CEYLON_USER_REPO} ${ceylon_repos} ${compile_files}
        
# Run user build
user_build.sh
