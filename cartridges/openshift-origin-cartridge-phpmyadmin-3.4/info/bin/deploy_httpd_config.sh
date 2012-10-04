#!/bin/bash

source "/etc/openshift/node.conf"
source "/etc/openshift/resource_limits.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

application="$1"
uuid="$2"
IP="$3"

APP_HOME="${GEAR_BASE_DIR}/$uuid"
PHPMYADMIN_DIR=`echo $APP_HOME/phpmyadmin-3.4 | tr -s /`

cat <<EOF > "$PHPMYADMIN_DIR/conf.d/openshift.conf"
ServerRoot "$PHPMYADMIN_DIR"
Listen $IP:8080
User $uuid
Group $uuid
ErrorLog "|/usr/sbin/rotatelogs $PHPMYADMIN_DIR/logs/error_log$rotatelogs_format $rotatelogs_interval"
CustomLog "|/usr/sbin/rotatelogs $PHPMYADMIN_DIR/logs/access_log$rotatelogs_format $rotatelogs_interval" combined

php_value include_path "."

# TODO: Adjust from ALL to more conservative values
#<IfModule !mod_bw.c>
#    LoadModule bw_module    modules/mod_bw.so
#</IfModule>
#
#<ifModule mod_bw.c>
#  BandWidthModule On
#  ForceBandWidthModule On
#  BandWidth $apache_bandwidth
#  MaxConnection $apache_maxconnection
#  BandWidthError $apache_bandwidtherror
#</IfModule>

EOF

cat <<EOF > "$PHPMYADMIN_DIR/conf.d/phpMyAdmin.conf"
Alias /phpmyadmin /usr/share/phpMyAdmin/

<Directory /usr/share/phpMyAdmin/>
   Order Allow,Deny
   Allow from All
</Directory>

# We set it up for them, this should not be necessary
<Directory /usr/share/phpMyAdmin/setup/>
   Order Deny,Allow
   Deny from All
</Directory>


# These directories do not require access over HTTP - taken from the original
# phpMyAdmin upstream tarball
#
<Directory /usr/share/phpMyAdmin/libraries/>
    Order Deny,Allow
    Deny from All
    Allow from None
</Directory>

<Directory /usr/share/phpMyAdmin/setup/lib/>
    Order Deny,Allow
    Deny from All
    Allow from None
</Directory>

<Directory /usr/share/phpMyAdmin/setup/frames/>
    Order Deny,Allow
    Deny from All
    Allow from None
</Directory>

EOF
