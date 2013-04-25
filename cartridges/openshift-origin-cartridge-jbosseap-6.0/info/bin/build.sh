#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

CONFIG_DIR="$CARTRIDGE_BASE_PATH/jbosseap-6.0/info/configuration"
OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.base.xml"
if `echo $OPENSHIFT_GEAR_DNS | egrep -qe "\.rhcloud\.com"`
then 
    OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.rhcloud.xml"
fi

max_memory_bytes=`oo-cgroup-read memory.limit_in_bytes`
max_memory_mb=`expr $max_memory_bytes / 1048576`

# If hot deploy is enabled, we need to restrict the Maven memory size to fit
# alongside the running application server. For now, just hard-code it to 64
# and figure out how to apply a scaling factor later.
if ! in_ci_build && hot_deploy_marker_is_present ; then
    echo "Scaling down Maven heap settings due to presence of hot_deploy marker"
    
    if [ -z $MAVEN_JVM_HEAP_RATIO ]; then
		MAVEN_JVM_HEAP_RATIO=0.25
	fi
else
	if [ -z $MAVEN_JVM_HEAP_RATIO ]; then
		MAVEN_JVM_HEAP_RATIO=0.75
	fi
fi

max_heap=$( echo "$max_memory_mb * $MAVEN_JVM_HEAP_RATIO" | bc | awk '{print int($1+0.5)}')

OPENSHIFT_MAVEN_XMX="-Xmx${max_heap}m"

if [ -z "$BUILD_NUMBER" ]
then
    SKIP_MAVEN_BUILD=false
    if git show master:.openshift/markers/skip_maven_build > /dev/null 2>&1
    then
        SKIP_MAVEN_BUILD=true
    fi
    
    if [ -f "${OPENSHIFT_REPO_DIR}/.openshift/markers/force_clean_build" ]
    then
        echo ".openshift/markers/force_clean_build found!  Removing Maven dependencies." 1>&2
        rm -rf ${OPENSHIFT_HOMEDIR}.m2/* ${OPENSHIFT_HOMEDIR}.m2/.[^.]*
    fi

    if [ -f ${OPENSHIFT_REPO_DIR}pom.xml ] && ! $SKIP_MAVEN_BUILD
    then
        if [ -e ${OPENSHIFT_REPO_DIR}.openshift/markers/java7 ];
        then
           export JAVA_HOME=/etc/alternatives/java_sdk_1.7.0
        else
          export JAVA_HOME=/etc/alternatives/java_sdk_1.6.0
        fi
        
        export M2_HOME=/etc/alternatives/maven-3.0
        export MAVEN_OPTS="$OPENSHIFT_MAVEN_XMX"
        export PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH
        pushd ${OPENSHIFT_REPO_DIR} > /dev/null
        
        if [ -f "${OPENSHIFT_REPO_DIR}/.openshift/action_hooks/pre_build_jbosseap-6.0" ]
        then
           echo "Sourcing pre_build_jbosseap-6.0" 1>&2
           source ${OPENSHIFT_REPO_DIR}/.openshift/action_hooks/pre_build_jbosseap-6.0
        fi
        
        if [ -z "$MAVEN_OPTS" ]; then
        	export MAVEN_OPTS="$OPENSHIFT_MAVEN_XMX"
        fi
        if [ -z "$MAVEN_ARGS" ]; then
		    export MAVEN_ARGS="clean package -Popenshift -DskipTests"
        fi
        
        echo "Found pom.xml... attempting to build with 'mvn -e ${MAVEN_ARGS}'"
        
        if [ -n "$OPENSHIFT_MAVEN_MIRROR" ]
        then
            mvn --global-settings $OPENSHIFT_MAVEN_MIRROR --version
            mvn --global-settings $OPENSHIFT_MAVEN_MIRROR $MAVEN_ARGS
        else
            mvn --version
            mvn $MAVEN_ARGS
        fi
        
        popd > /dev/null
        
        CART_NAME=jbosseap-6.0
        if [ ! -h ${OPENSHIFT_REPO_DIR}/deployments ] && [ ! -h ${OPENSHIFT_HOMEDIR}/${CART_NAME}/${CART_NAME}/standalone/deployments ]
		then
		    if [ "$(ls ${OPENSHIFT_REPO_DIR}/deployments)" ]; then
  				rsync -r --delete-after --exclude=".*" --exclude='*.deployed' --exclude='*.deploying' --exclude='*.isundeploying' ${OPENSHIFT_REPO_DIR}/deployments/ ${OPENSHIFT_HOMEDIR}/${CART_NAME}/${CART_NAME}/standalone/deployments/
  			else
    			rm -rf ${OPENSHIFT_HOMEDIR}/${CART_NAME}/${CART_NAME}/standalone/deployments/*
    		fi
		fi
    fi
else
    export OPENSHIFT_MAVEN_MIRROR
    export OPENSHIFT_MAVEN_XMX
fi

user_build.sh
