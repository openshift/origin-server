#!/bin/bash
echo "Import cartridges"
find /var/www/openshift/cartridges -iname manifest.yml | oo-admin-ctl-cartridge -c import --activate

echo "Populate node location for geard"
/var/www/openshift/broker-util/oo-admin-ctl-node -c create --name default --server_identity 172.17.42.1:43273