Before('@manipulates_gear_upgrade') do
  clean_gear_upgrade_extension_from_node_conf
end

After('@manipulates_gear_upgrade') do
  clean_gear_upgrade_extension_from_node_conf
end

def clean_gear_upgrade_extension_from_node_conf
  `sed -i /etc/openshift/node.conf -e /GEAR_UPGRADE_EXTENSION/d`
  `sed -i /etc/openshift/node.conf -e '${/^$/d}'`
end
