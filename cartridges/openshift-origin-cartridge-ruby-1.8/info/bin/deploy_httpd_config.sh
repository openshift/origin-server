#!/bin/bash

cartridge_type="ruby-1.8"
source "/etc/openshift/node.conf"
source "/etc/openshift/resource_limits.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

application="$1"
uuid="$2"
IP="$3"

APP_HOME="${GEAR_BASE_DIR}/$uuid"
RUBY_INSTANCE_DIR=$(get_cartridge_instance_dir "$cartridge_type")
source "$APP_HOME/.env/OPENSHIFT_REPO_DIR"

# FIXME: Remove this after PassengerSpawnIPAddress change is upstreamed.
LINUX_DISTRO=$(</etc/redhat-release)
RED_HAT_DISTRO_NAME="Red Hat"
SPAWN_IP=""

if [[ "$LINUX_DISTRO" =~ $RED_HAT_DISTRO_NAME* ]]
then
    SPAWN_IP="PassengerSpawnIPAddress $IP"
fi

cat <<EOF > "$RUBY_INSTANCE_DIR/conf.d/openshift.conf"
ServerRoot "$RUBY_INSTANCE_DIR"
DocumentRoot "$OPENSHIFT_REPO_DIR/public"
Listen $IP:8080
User $uuid
Group $uuid

ErrorLog "|/usr/sbin/rotatelogs $RUBY_INSTANCE_DIR/logs/error_log$rotatelogs_format $rotatelogs_interval"
CustomLog "|/usr/sbin/rotatelogs $RUBY_INSTANCE_DIR/logs/access_log$rotatelogs_format $rotatelogs_interval" combined

PassengerUser $uuid
PassengerPreStart http://$IP:8080/
$SPAWN_IP
PassengerUseGlobalQueue off
<Directory $OPENSHIFT_REPO_DIR/public>
  AllowOverride all
  Options -MultiViews
</Directory>

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
