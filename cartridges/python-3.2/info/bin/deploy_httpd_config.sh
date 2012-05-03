#!/bin/bash

source "/etc/stickshift/stickshift-node.conf"
source "/etc/stickshift/resource_limits.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

application="$1"
uuid="$2"
IP="$3"

APP_HOME="$GEAR_BASE_DIR/$uuid"
APP_DIR=`echo $APP_HOME/$application | tr -s /`
source "$APP_HOME/.env/OPENSHIFT_LOG_DIR"
source "$APP_HOME/.env/OPENSHIFT_REPO_DIR"

cat <<EOF > "$APP_DIR/conf.d/stickshift.conf"
ServerRoot "$APP_DIR"
DocumentRoot "$OPENSHIFT_REPO_DIR/wsgi"
Listen $IP:8080
User $uuid
Group $uuid

ErrorLog "|/usr/sbin/rotatelogs $OPENSHIFT_LOG_DIR/error_log$rotatelogs_format $rotatelogs_interval"
CustomLog "|/usr/sbin/rotatelogs $OPENSHIFT_LOG_DIR/access_log$rotatelogs_format $rotatelogs_interval" combined
 
<Directory $OPENSHIFT_REPO_DIR/wsgi>
  AllowOverride all
  Options -MultiViews
</Directory>

WSGIScriptAlias / "$OPENSHIFT_REPO_DIR/wsgi/application"
Alias /static "$OPENSHIFT_REPO_DIR/wsgi/static/"
WSGIPythonPath "$OPENSHIFT_REPO_DIR/libs:$OPENSHIFT_REPO_DIR/wsgi:$APP_DIR/virtenv/lib/python2.6/"
WSGIPassAuthorization On

# TODO: Adjust from ALL to more conservative values
<IfModule !mod_bw.c>
    LoadModule bw_module    modules/mod_bw.so
</IfModule>

<ifModule mod_bw.c>
  BandWidthModule On
  ForceBandWidthModule On
  BandWidth $apache_bandwidth
  MaxConnection $apache_maxconnection
  BandWidthError $apache_bandwidtherror
</IfModule>


EOF
