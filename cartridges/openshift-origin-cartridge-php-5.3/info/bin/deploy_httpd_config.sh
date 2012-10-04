#!/bin/bash

cartridge_type="php-5.3"
source "/etc/openshift/node.conf"
source "/etc/openshift/resource_limits.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

application="$1"
uuid="$2"
IP="$3"

APP_HOME="$GEAR_BASE_DIR/$uuid"
PHP_INSTANCE_DIR=$(get_cartridge_instance_dir "$cartridge_type")
source "$APP_HOME/.env/OPENSHIFT_REPO_DIR"

cat <<EOF > "$PHP_INSTANCE_DIR/conf.d/openshift.conf"
ServerRoot "$PHP_INSTANCE_DIR"
DocumentRoot "$OPENSHIFT_REPO_DIR/php"
Listen $IP:8080
User $uuid
Group $uuid
ErrorLog "|/usr/sbin/rotatelogs $PHP_INSTANCE_DIR/logs/error_log$rotatelogs_format $rotatelogs_interval"
CustomLog "|/usr/sbin/rotatelogs $PHP_INSTANCE_DIR/logs/access_log$rotatelogs_format $rotatelogs_interval" combined
php_value include_path ".:$OPENSHIFT_REPO_DIR/libs/:$PHP_INSTANCE_DIR/phplib/pear/pear/php/:/usr/share/pear/"
# TODO: Adjust from ALL to more conservative values
<Directory "$OPENSHIFT_REPO_DIR/php">
  AllowOverride All
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
