#!/bin/bash

cartridge_type="perl-5.10"
source "/etc/openshift/node.conf"
source "/etc/openshift/resource_limits.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

load_resource_limits_conf

application="$1"
uuid="$2"
IP="$3"

APP_HOME="$GEAR_BASE_DIR/$uuid"
PERL_INSTANCE_DIR=$(get_cartridge_instance_dir "$cartridge_type")
source "$APP_HOME/.env/OPENSHIFT_REPO_DIR"

cat <<EOF > "$PERL_INSTANCE_DIR/conf.d/openshift.conf"
ServerRoot "$PERL_INSTANCE_DIR"
DocumentRoot "$OPENSHIFT_REPO_DIR/perl"
Listen $IP:8080
User $uuid
Group $uuid
ErrorLog "|/usr/sbin/rotatelogs $PERL_INSTANCE_DIR/logs/error_log$rotatelogs_format $rotatelogs_interval"
CustomLog "|/usr/sbin/rotatelogs $PERL_INSTANCE_DIR/logs/access_log$rotatelogs_format $rotatelogs_interval" combined

<Directory $OPENSHIFT_REPO_DIR/perl/>
    AddHandler perl-script .pl
    AddHandler cgi-script .cgi
    PerlResponseHandler ModPerl::Registry
    PerlOptions +ParseHeaders
    Options +ExecCGI
    DirectoryIndex index.pl
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
