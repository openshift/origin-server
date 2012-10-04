#!/bin/bash
set -e

# Import Environment Variables
for f in ~/.env/*
do
    . $f
done

WORKING_DIR=$1
GIT_DIR=$2

source "/etc/openshift/node.conf"

export OPENSHIFT_SKIP_GIT_HOOKS="true"
rm -rf $WORKING_DIR 
git clone $GIT_DIR $WORKING_DIR
pushd $WORKING_DIR > /dev/null
    if [ -f .openshift/config/standalone.xml ]
    then
	    xsltproc -o .openshift/config/standalone.xml ${CARTRIDGE_BASE_PATH}/jbossas-7/info/configuration/as-7.0.2-as-7.1.0.xsl .openshift/config/standalone.xml
	    sed -i -e "s/\${OPENSHIFT_/\${env.OPENSHIFT_/g" -e "s/<loopback-address value=\".*\"\/>/<loopback-address value=\"\${env.OPENSHIFT_INTERNAL_IP}\"\/>/g" .openshift/config/standalone.xml 
	    git add -f .openshift/config/standalone.xml
	    if git commit -m 'Updating .openshift/config/standalone.xml to be 7.1.0 compatible'
	    then
	        git push origin master
	    else
	        echo "WARNING: No changes made to standalone.xml!"
	    fi
    else
        echo "WARNING: standalone.xml not found!"
    fi
popd > /dev/null;
rm -rf $WORKING_DIR