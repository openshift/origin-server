#!/bin/bash
# Script to disable the local serving gear after either atleast
# one remote gear is visible to haproxy or 30 seconds have passed.
set -x
rm -f /tmp/fix_local*
exec &> /tmp/fix_local.$$

prim_cart=$(grep "Cartridge-Short-Name" $OPENSHIFT_PRIMARY_CARTRIDGE_DIR/metadata/manifest.yml | cut -d: -f2 | xargs)
prim_cart_ip="OPENSHIFT_${prim_cart}_IP"
prim_cart_port="OPENSHIFT_${prim_cart}_PORT"
eval local_ip=\$${prim_cart_ip}
if [ -z "$local_ip" ]; then
    first_ip_in_manifest=$(grep Endpoints: $OPENSHIFT_PRIMARY_CARTRIDGE_DIR/metadata/manifest.yml -A 5 | grep Private-IP-Name | cut -d":" -f2  | xargs)
    prim_cart_ip="OPENSHIFT_${prim_cart}_${first_ip_in_manifest}"
    eval local_ip=\$${prim_cart_ip}
fi
eval local_port=\$${prim_cart_port}
if [ -z "$local_port" ]; then
    first_port_in_manifest=$(grep Endpoints: $OPENSHIFT_PRIMARY_CARTRIDGE_DIR/metadata/manifest.yml -A 5 | grep Private-Port-Name | cut -d":" -f2  | xargs)
    prim_cart_port="OPENSHIFT_${prim_cart}_${first_port_in_manifest}"
    eval local_port=\$${prim_cart_port}
fi
local_ep=$local_ip:$local_port

haproxy_cfg=$OPENSHIFT_HAPROXY_DIR/conf/haproxy.cfg
iter=0

while (( $iter < 30 )); do
    echo "$iter: Checking if any remote gears are up."
    if [ $(curl -sS "$OPENSHIFT_HAPROXY_STATUS_IP:$OPENSHIFT_HAPROXY_STATUS_PORT/haproxy-status/;csv" | grep gear- | grep UP | wc -l) -ge 1 ]; then
        echo "Atleast one remote gear is UP."
        break;
    else
        sleep 1
        iter=$((iter + 1))
    fi
done
(
 flock -e 200
 echo "Disabling local-gear"
 cp -f $haproxy_cfg /tmp/haproxy.cfg.$$
 ## disable local-gear serving with weight 0.
 sed -i "/\s*server\s*local-gear\s.*/d" /tmp/haproxy.cfg.$$
 echo "    server local-gear $local_ep weight 0" >> /tmp/haproxy.cfg.$$
 cat /tmp/haproxy.cfg.$$ > "$haproxy_cfg"
 rm -f /tmp/haproxy.cfg.$$
) 200>${haproxy_cfg}.lock

# Restart haproxy to pick up the new configuration
/usr/bin/gear reload --cart haproxy-$OPENSHIFT_HAPROXY_VERSION
