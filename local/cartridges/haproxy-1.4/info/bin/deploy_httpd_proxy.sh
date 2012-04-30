#!/bin/bash

#
# Create virtualhost definition for apache
#
# node_ssl_template.conf gets copied in unaltered and should contain
# all of the configuration bits required for ssl to work including key location
#
function print_help {
    echo "Usage: $0 app-name namespace uuid IP"

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

vhost="${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}.conf"
if [ -f "$vhost" ]; then
   #  Already have a vhost - just add haproxy routing to it.
   cat <<EOF > "${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}/000000_haproxy.conf"
  ProxyPass /haproxy-status/ http://$IP2:8080/ status=I
  ProxyPassReverse /haproxy-status/ http://$IP2:8080/
EOF
   exit $?
fi

rm -rf "${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}.conf" "${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}"

mkdir "${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}"

cat <<EOF > "${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}/00000_default.conf"
  ServerName ${application}-${namespace}.${CLOUD_DOMAIN}
  ServerAdmin mmcgrath@redhat.com
  DocumentRoot /var/www/html
  DefaultType None

  ProxyPass /health !
  Alias /health ${CARTRIDGE_BASE_PATH}/haproxy-1.4/info/configuration/health.html

  ProxyPass /haproxy-status/ http://$IP2:8080/ status=I
  ProxyPassReverse /haproxy-status/ http://$IP2:8080/
  ProxyPass / http://$IP:8080/ status=I
  ProxyPassReverse / http://$IP:8080/
EOF
cat <<EOF > "${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}.conf"
<VirtualHost *:80>
  RequestHeader append X-Forwarded-Proto "http"

  Include ${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}/*.conf

</VirtualHost>

<VirtualHost *:443>
  RequestHeader append X-Forwarded-Proto "https"

$(/bin/cat ${CARTRIDGE_BASE_PATH}/haproxy-1.4/info/configuration/node_ssl_template.conf)

  Include ${STICKSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}/*.conf

</VirtualHost>
EOF
