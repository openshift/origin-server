#!/bin/bash

# Embeds switchyard into an JBoss instance

# Exit on any errors
set -e

function print_help {
    echo "Usage: $0 app-name namespace uuid"

    echo "$0 $@" | logger -p local0.notice -t openshift_origin_switchyard_configure
    exit 1
}

while getopts 'd' OPTION
do
    case $OPTION in
        d) set -x
        ;;
        ?) print_help
        ;;
    esac
done


[ $# -eq 3 ] || print_help

cartridge_type="switchyard-0.6"
source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

setup_embedded_configure "$1" $2 $3

#
# Create the core of the application
#

if [ ! -f "$APP_HOME/.env/OPENSHIFT_JBOSSEAP_CLUSTER" ] && [ ! -f "$APP_HOME/.env/OPENSHIFT_JBOSSAS_CLUSTER" ]
then
  client_error "SwitchYard is only supported for JBoss AS/EAP"
  exit 152
fi

module_path="OPENSHIFT_JBOSSAS_MODULE_PATH"
if [ -f "$APP_HOME/.env/OPENSHIFT_JBOSSEAP_CLUSTER" ]
then
  module_path="OPENSHIFT_JBOSSEAP_MODULE_PATH"
fi

if [ -f "$APP_HOME/.env/$module_path" ]
then
     if grep -q "switchyard" "$APP_HOME/.env/$module_path"; then
       client_error "SwitchYard already embedded in $application"
       exit 152
     fi
     
     . $APP_HOME/.env/$module_path
fi

#
# Setup Environment Variables
#
if [ -f "$APP_HOME/.env/$module_path" ]
then
	echo "export $module_path='${$module_path}:/etc/alternatives/switchyard-0.6/modules'" > $APP_HOME/.env/$module_path
else
    echo "export $module_path='/etc/alternatives/switchyard-0.6/modules'" > $APP_HOME/.env/$module_path
fi

source $APP_HOME/.env/$module_path

#if [ -f "$APP_HOME/.env/OPENSHIFT_JBOSSEAP_CLUSTER" ]
#then
#	java  -jar ${CARTRIDGE_BASE_PATH}/embedded/switchyard-0.6/info/configuration/saxon9he.jar \
#		${APP_HOME}/app-root/runtime/repo/.openshift/config/standalone.xml \
#		${CARTRIDGE_BASE_PATH}/embedded/switchyard-0.6/info/configuration/standalone_eap6.0.0.xsl > ${APP_HOME}/app-root/runtime/repo/.openshift/config/standalone.xml.new
#else
#    java  -jar ${CARTRIDGE_BASE_PATH}/embedded/switchyard-0.6/info/configuration/saxon9he.jar \
#		${APP_HOME}/app-root/runtime/repo/.openshift/config/standalone.xml \
#		${CARTRIDGE_BASE_PATH}/embedded/switchyard-0.6/info/configuration/standalone_as7.1.0.xsl > ${APP_HOME}/app-root/runtime/repo/.openshift/config/standalone.xml.new
#fi
#mv ${APP_HOME}/app-root/runtime/repo/.openshift/config/standalone.xml.new ${APP_HOME}/app-root/runtime/repo/.openshift/config/standalone.xml

client_result ""
client_result "SwitchYard 0.6 added."
client_result ""

cart_props "module_path=/etc/alternatives/switchyard-0.6/modules"