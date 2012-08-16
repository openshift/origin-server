#!/bin/bash

#
# Create virtualhost definition for apache
#
# node_ssl_template.conf gets copied in unaltered and should contain
# all of the configuration bits required for ssl to work including key location
#
function print_help {
    echo "Usage: $0 app-name namespace uuid"

    echo "$0 $@" | logger -p local0.notice -t stickshift_deploy_httpd_proxy
    exit 1
}

[ $# -eq 4 ] || print_help


application="$1"
namespace=`basename $2`
uuid=$3
IP=$4

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

cat <<EOF > "/etc/httpd/conf.d/stickshift/${uuid}_${namespace}_${application}/postgresql-8.4.conf"
  Alias /health $CART_INFO_DIR/configuration/health.html
  Alias / $CART_INFO_DIR/configuration/index.html
EOF

cat <<EOF > "/etc/httpd/conf.d/stickshift/${uuid}_${namespace}_${application}/00000_default.conf"
  ServerName ${application}-${namespace}.${CLOUD_DOMAIN}
  ServerAdmin mmcgrath@redhat.com
  DocumentRoot /var/www/html
  DefaultType None
EOF

cat <<EOF > "/etc/httpd/conf.d/stickshift/${uuid}_${namespace}_${application}.conf"
<VirtualHost *:80>
  RequestHeader append X-Forwarded-Proto "http"

  Include /etc/httpd/conf.d/stickshift/${uuid}_${namespace}_${application}/*.conf
</VirtualHost>

<VirtualHost *:443>
  RequestHeader append X-Forwarded-Proto "https"

$(/bin/cat $CART_INFO_DIR/configuration/node_ssl_template.conf)

  Include /etc/httpd/conf.d/stickshift/${uuid}_${namespace}_${application}/*.conf
</VirtualHost>
EOF
