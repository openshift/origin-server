#!/bin/bash

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

source "/etc/stickshift/stickshift-node.conf"

CONFIG_DIR="$CARTRIDGE_BASE_PATH/$OPENSHIFT_GEAR_TYPE/info/configuration"
if `echo $OPENSHIFT_GEAR_DNS | grep -q .stg.rhcloud.com` || `echo $OPENSHIFT_GEAR_DNS | grep -q .dev.rhcloud.com`
then 
	OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.stg.xml"
elif `echo $OPENSHIFT_GEAR_DNS | grep -q .rhcloud.com`
then
	OPENSHIFT_MAVEN_MIRROR="$CONFIG_DIR/settings.prod.xml"
fi

resource_limits_file=`readlink -f /etc/stickshift/resource_limits.conf`
resource_limits_file_name=`basename $resource_limits_file`
node_profile=`echo ${resource_limits_file_name/*./}`
case "$node_profile" in
	micro)
        OPENSHIFT_MAVEN_XMX="-Xmx208m"
    ;;
    small)
        OPENSHIFT_MAVEN_XMX="-Xmx396m"
    ;;
    medium)
        OPENSHIFT_MAVEN_XMX="-Xmx792m"
    ;;
    large)
        OPENSHIFT_MAVEN_XMX="-Xmx1584m"
    ;;
    exlarge)
        OPENSHIFT_MAVEN_XMX="-Xmx1584m"
    ;;
    jumbo)
        OPENSHIFT_MAVEN_XMX="-Xmx1584m"
    ;;
esac

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

        #pushd ${OPENSHIFT_HOMEDIR}.m2/ > /dev/null
        #tar -xf ${CARTRIDGE_BASE_PATH}/${OPENSHIFT_GEAR_TYPE}/info/data/m2_repository.tar.gz
        #popd > /dev/null
    fi

    if [ -f ${OPENSHIFT_REPO_DIR}pom.xml ] && ! $SKIP_MAVEN_BUILD
    then
        echo "Found pom.xml... attempting to build with 'mvn -e clean package -Popenshift -DskipTests'" 
        export JAVA_HOME=/etc/alternatives/java_sdk_1.6.0
        export M2_HOME=/etc/alternatives/maven-3.0
        export MAVEN_OPTS="$OPENSHIFT_MAVEN_XMX"
        export PATH=$JAVA_HOME/bin:$M2_HOME/bin:$PATH
        pushd ${OPENSHIFT_REPO_DIR} > /dev/null
        if [ -n "$OPENSHIFT_MAVEN_MIRROR" ]
        then
            mvn --global-settings $OPENSHIFT_MAVEN_MIRROR --version
            mvn --global-settings $OPENSHIFT_MAVEN_MIRROR clean package -Popenshift -DskipTests
        else
            mvn --version
            mvn clean package -Popenshift -DskipTests
        fi
        popd > /dev/null
    fi
else
    export OPENSHIFT_MAVEN_MIRROR
    export OPENSHIFT_MAVEN_XMX
fi

user_build.sh
