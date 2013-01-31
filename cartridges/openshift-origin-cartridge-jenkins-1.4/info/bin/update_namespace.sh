#!/bin/bash

# Exit on any errors
set -e

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util
CART_INFO_DIR=${CARTRIDGE_BASE_PATH}/jenkins-1.4/info

function print_help {
    echo "Usage: $0 app-name new_namespace old_namespace uuid"

    echo "$0 $@" | logger -p local0.notice -t openshift_origin_jenkins_update_namespace
    exit 1
}

[ $# -eq 4 ] || print_help

application="$1"
new_namespace="$2"
old_namespace="$3"
uuid=$4

setup_app_dir_vars
setup_user_vars

echo "export JENKINS_URL='https://${application}-${new_namespace}.${CLOUD_DOMAIN}/'" > $APP_HOME/.env/JENKINS_URL
. $APP_HOME/.env/OPENSHIFT_INTERNAL_IP
. $APP_HOME/.env/OPENSHIFT_INTERNAL_PORT
. $APP_HOME/.env/JENKINS_URL
. $APP_HOME/.env/JENKINS_USERNAME
. $APP_HOME/.env/JENKINS_PASSWORD
. $APP_HOME/.env/OPENSHIFT_JENKINS_IP
. $APP_HOME/.env/OPENSHIFT_JENKINS_PORT
. $APP_HOME/.env/OPENSHIFT_DATA_DIR

jobs_path="$APP_HOME/app-root/data/jobs"
if ls $jobs_path/*/config.xml > /dev/null 2>&1
then
    sed -i "s/-${old_namespace}.${CLOUD_DOMAIN}/-${new_namespace}.${CLOUD_DOMAIN}/g" $jobs_path/*/config.xml

    # POST each config XML back to Jenkins to ensure the contents are reloaded
    # into memory
    for job_path in $jobs_path/*; do
      job=$(basename $job_path)
      config_url="http://$OPENSHIFT_JENKINS_IP:$OPENSHIFT_JENKINS_PORT/job/$job/config.xml"
      config_file=$jobs_path/$job/config.xml
      curl -X POST --user $JENKINS_USERNAME:$JENKINS_PASSWORD --data-binary @${config_file} $config_url > /dev/null 2>&1
    done
fi

if [ -f $APP_HOME/app-root/data/config.xml ]
then
    sed -i "s/-${old_namespace}.${CLOUD_DOMAIN}/-${new_namespace}.${CLOUD_DOMAIN}/g" $APP_HOME/app-root/data/config.xml
fi

if [ -f $APP_HOME/app-root/data/hudson.tasks.Mailer.xml ]
then
    sed -i "s/-${old_namespace}.${CLOUD_DOMAIN}/-${new_namespace}.${CLOUD_DOMAIN}/g" $APP_HOME/app-root/data/hudson.tasks.Mailer.xml
fi

add_env_var "JENKINS_URL=https://${application}-${new_namespace}.${CLOUD_DOMAIN}/"
