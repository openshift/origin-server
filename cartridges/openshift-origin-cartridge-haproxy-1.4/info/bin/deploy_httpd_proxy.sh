#!/bin/bash

#
# Create virtualhost definition for apache
#
# node_ssl_template.conf gets copied in unaltered and should contain
# all of the configuration bits required for ssl to work including key location
#
function print_help {
    echo "Usage: $0 app-name namespace uuid IP"

    echo "$0 $@" | logger -p local0.notice -t openshift_origin_deploy_httpd_proxy
    exit 1
}

[ $# -eq 4 ] || print_help


application="$1"
namespace=`basename $2`
uuid=$3
IP=$4

source "/etc/openshift/node.conf"
source ${CARTRIDGE_BASE_PATH}/abstract/info/lib/util

setup_app_dir_vars
setup_user_vars

export CART_INFO_DIR=${CARTRIDGE_BASE_PATH}/embedded/haproxy-1.4/info

vhost="${OPENSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}.conf"
if [ ! -f "$vhost" ]; then
   ${CARTRIDGE_BASE_PATH}/abstract/info/bin/deploy_httpd_proxy.sh "$@"
fi

#  Already have a vhost - just add haproxy routing to it.
cat <<EOF > "${OPENSHIFT_HTTP_CONF_DIR}/${uuid}_${namespace}_${application}/000000_haproxy.conf"
  ProxyPass /health !
  Alias /health ${CART_INFO_DIR}/configuration/health.html
  ProxyPass /haproxy-status/ http://$IP2:8080/ status=I
  ProxyPassReverse /haproxy-status/ http://$IP2:8080/
  ProxyPass / http://$IP:8080/ status=I
  ProxyPassReverse / http://$IP:8080/
EOF

cat <<EOF > "/etc/httpd/conf.d/openshift/${uuid}_${namespace}_${application}/routes.json"
{
  "${application}-${namespace}.${CLOUD_DOMAIN}": {
    "endpoints": [ "$IP:8080" ],
    "limits"   :  {
      "connections": -1,
      "bandwidth"  : 100
    }
  }
}
EOF

service openshift-node-web-proxy reload
