#!/bin/bash

cartridge_type="python-2.6"
source "/etc/openshift/node.conf"
source "/etc/openshift/resource_limits.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

application="$1"
uuid="$2"
IP="$3"

APP_HOME="$GEAR_BASE_DIR/$uuid"
PYCART_INSTANCE_DIR=$(get_cartridge_instance_dir "$cartridge_type")
source "$APP_HOME/.env/OPENSHIFT_REPO_DIR"

cat <<EOF > "$PYCART_INSTANCE_DIR/conf.d/openshift.conf"
ServerRoot "$PYCART_INSTANCE_DIR"
DocumentRoot "$OPENSHIFT_REPO_DIR/wsgi"
Listen $IP:8080
User $uuid
Group $uuid

ErrorLog "|/usr/sbin/rotatelogs $PYCART_INSTANCE_DIR/logs/error_log$rotatelogs_format $rotatelogs_interval"
CustomLog "|/usr/sbin/rotatelogs $PYCART_INSTANCE_DIR/logs/access_log$rotatelogs_format $rotatelogs_interval" combined
 
<Directory $OPENSHIFT_REPO_DIR/wsgi>
  AllowOverride all
  Options -MultiViews
</Directory>

WSGIScriptAlias / "${OPENSHIFT_REPO_DIR}wsgi/application"
Alias /static "${OPENSHIFT_REPO_DIR}wsgi/static/"
#WSGIPythonPath "${OPENSHIFT_REPO_DIR}libs:${OPENSHIFT_REPO_DIR}wsgi:$PYCART_INSTANCE_DIR/virtenv/lib/python2.6/"
WSGIPassAuthorization On

WSGIProcessGroup $uuid
WSGIDaemonProcess $uuid user=$uuid group=$uuid processes=2 threads=25 python-path="${OPENSHIFT_REPO_DIR}libs:${OPENSHIFT_REPO_DIR}wsgi:$PYCART_INSTANCE_DIR/virtenv/lib/python2.6/"

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
