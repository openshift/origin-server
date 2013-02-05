#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

cartridge_type="ceylon-0.5"

if [ -f "${OPENSHIFT_REPO_DIR}/.openshift/action_hooks/pre_build_jbossas-7" ]
then
   echo "Sourcing pre_build_jbossas-7" 1>&2
   source ${OPENSHIFT_REPO_DIR}/.openshift/action_hooks/pre_build_ceylon
fi
        
find ${OPENSHIFT_REPO_DIR}/source/ -name *\.ceylon -o -name *\.java -print0 | xargs -0 -I% " compile %"
compile_files=`find source/ -name *\.ceylon -o -name *\.java`
printf "Compiling files:\n$files\n"
${CEYLON_HOME}/bin/ceylon compile --out ${CEYLON_REPO} ${compile_files}
        
# Run user build
user_build.sh
