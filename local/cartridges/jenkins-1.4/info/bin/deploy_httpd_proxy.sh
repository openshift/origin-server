#!/bin/bash

#
# Create virtualhost definition for apache
#
# node_ssl_template.conf gets copied in unaltered and should contain
# all of the configuration bits required for ssl to work including key location
#
function print_help {
    echo "Usage: $0 app-name namespace uuid IP"

    echo "$0 $@" | logger -p local0.notice -t stickshift_jenkins_deploy_httpd_proxy
    exit 1
}

[ $# -eq 4 ] || print_help


application="$1"
namespace=`basename $2`
uuid=$3
IP=$4

source "/etc/stickshift/stickshift-node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

rm -rf "${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}.conf" "${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}"

mkdir "${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}"

cat <<EOF > "${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}/00000_default.conf"
  ServerName ${application}-${namespace}.${CLOUD_DOMAIN}
  ServerAdmin mmcgrath@redhat.com
  DocumentRoot /var/www/html
  DefaultType None
EOF
cat <<EOF > "${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}.conf"
<VirtualHost *:80>
  RequestHeader append X-Forwarded-Proto "http"

  Include ${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}/*.conf
  
  RewriteEngine on
  RewriteCond %{HTTPS} off
  RewriteRule /health ${CARTRIDGE_BASE_PATH}/jenkins-1.4/info/configuration/health [L]
  RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</VirtualHost>

<VirtualHost *:443>
  RequestHeader append X-Forwarded-Proto "https"

$(/bin/cat $CART_INFO_DIR/configuration/node_ssl_template.conf)

  Include ${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}/*.conf
  
  ##RewriteEngine On
  ##RewriteRule /health ${CARTRIDGE_BASE_PATH}/jenkins-1.4/info/configuration/health [L]
  Alias /health ${CARTRIDGE_BASE_PATH}/jenkins-1.4/info/configuration/health
  ProxyPass /health !
  ProxyPass / http://$IP:8080/ status=I
  ProxyPassReverse / http://$IP:8080/
</VirtualHost>
EOF
