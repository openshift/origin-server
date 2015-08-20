Given /^a version of the ([^ ]+)\-([\d\.]+) cartridge with additional published ENV vars is installed$/ do |cart_name, component_version|
  # Add a new hook that publishes an unique marker variable we can then check for
  garbage_hook_content = <<-EOF
#!/bin/bash
echo OPENSHIFT_MOCK_PLUGIN_GARBAGE=junk
EOF
  new_hooks = [ { :name => "publish-garbage-info",
                  :content => garbage_hook_content } ]

  current_manifest = prepare_cart_for_rewrite(cart_name, component_version)
  rewrite_and_install(current_manifest, @manifest_path, new_hooks) do |manifest, current_version|
    # Advertise unique marker in publishing manifest
    manifest['Publishes']['publish-garbage-info'] = {'Type' => 'ENV:NET_TCP:garbage:info'}
    manifest['Compatible-Versions'] = [ current_version ]
  end

end

Given /^a version of the ([^ ]+)\-([\d\.]+) cartridge with(out)? wildcard ENV subscription is installed$/ do |cart_name, component_version, negate|
  current_manifest = prepare_cart_for_rewrite(cart_name, component_version)
  rewrite_and_install(current_manifest, @manifest_path) do |manifest, current_version|
    manifest['Compatible-Versions'] = [ current_version ]
    if negate
      # Remove wildcard ENV var subscription if it exists
      manifest['Subscribes'].delete_if do |connection, params|
        params['Type'] == 'ENV:*'
      end
      # Add targeted ENV var subscriptions
      manifest['Subscribes'] = {
        'set-db-connection-info' => {
          'Type' => "ENV:NET_TCP:db:connection-info",
          'Required' => false
        },
        'set-nosql-db-connection-info' => {
          'Type' => "ENV:NET_TCP:nosqldb:connection-info",
          'Required' => false
        } }
    else
      # Remove any targeted ENV var subscriptions
      manifest['Subscribes'].delete_if do |connection, params|
        params['Type'].start_with? 'ENV:'
      end
      # Add wildcard ENV var subscription
      manifest['Subscribes']['set-env'] = { 'Type' => 'ENV:*', 'Required' => 'false' }
    end
  end
end

Given /^the broker cache is cleared$/ do
  %x(/usr/sbin/oo-admin-ctl-cartridge -c import-node --activate)
end

Then /^the ([^ ]+) application environment variable ([^ ]+) will( not)? exist$/ do |cart_name, cart_var, negate|
  var_name = "OPENSHIFT_#{cart_var}"
  var_file_path = File.join($home_root, @app.uid, '.env', cart_name, var_name)
  check_var_name(var_file_path, nil, negate)
end
