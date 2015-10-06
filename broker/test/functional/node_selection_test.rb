ENV["TEST_NAME"] = "functional_node_selection_plugin_test"
require 'test_helper'

class NodeSelectionPluginTest < ActiveSupport::TestCase

  def setup
    @@login = "user#{gen_uuid[0..9]}"
    @@namespace = "ns#{gen_uuid[0..9]}"
    @@appname = "app#{gen_uuid[0..9]}"
    @@gi_id = Moped::BSON::ObjectId.new
    @@gear_id = Moped::BSON::ObjectId.new

    @@server_id = OpenShift::MCollectiveApplicationContainerProxy.find_one_impl

    php, haproxy = cartridge_instances_for(:php, :haproxy)

    @@web_cart_name = php.name
    @@web_comp_name = php.components.first.name
    @@proxy_cart_name = haproxy.name
    @@proxy_comp_name = haproxy.components.first.name
    @@group_overrides = [GroupOverride.new([ComponentOverrideSpec.new(haproxy.to_component_spec, nil, nil, 1)], [ComponentOverrideSpec.new(php.to_component_spec, nil, nil, 1)])]
    
    # use this to toggle the response from the node selector plugin
    @@reurn_invalid_node = false
  end

  def self.select_best_fit_node_impl(node_list, app_props, current_gears, comp_list, user_props, request_time)
    raise Exception.new("Node list is empty") if node_list.empty?
    raise Exception.new("Node expected: #{@@server_id}; Node found: #{node_list[0].name}") if node_list[0].name != @@server_id

    raise Exception.new("Application properties not specified") if app_props.nil?
    raise Exception.new("Application name mismatch") if app_props.name != @@appname
    raise Exception.new("Domain namespace mismatch") if app_props.namespace != @@namespace

    raise Exception.new("Current gears list is empty") if current_gears.empty?
    raise Exception.new("Current gear count mismatch") if current_gears.length != 1
    raise Exception.new("Current gear name mismatch") if current_gears[0].name != @@gear_id.to_s
    raise Exception.new("Current gear server mismatch") if current_gears[0].server != @@server_id

    raise Exception.new("User properties not specified") if user_props.nil?
    raise Exception.new("User login mismatch") if user_props.login != @@login

    raise Exception.new("Component instances not specified") if comp_list.empty?
    raise Exception.new("Component count mismatch") if comp_list.length != 1
    raise Exception.new("Cartridge name mismatch") if comp_list[0].cartridge_name != @@web_cart_name
    raise Exception.new("Component name mismatch") if comp_list[0].component_name != @@web_comp_name

    raise Exception.new("Request time not specified") if request_time.nil?

    if @@reurn_invalid_node
      return "serverid"
    else
      return node_list[0]
    end
  end

  test "external node selection plugin" do
    OpenShift::ApplicationContainerProxy.node_selector_plugin = self.class

    user = CloudUser.new(login: @@login)
    user.save
    domain = Domain.new(namespace: @@namespace, owner: user)
    domain.save
    app = Application.new(name: @@appname, domain: domain)
    gi = GroupInstance.new({:custom_id => @@gi_id})
    app.group_instances.push gi
    gear = Gear.new({:custom_id => @@gear_id, :group_instance => gi})
    gear.server_identity = @@server_id
    app.gears.push gear
    new_gear = Gear.new({:custom_id => Moped::BSON::ObjectId.new, :group_instance => gi})
    app.gears.push new_gear
    ci = ComponentInstance.new(cartridge_name: @@web_cart_name, component_name: @@web_comp_name, group_instance_id: gi._id)
    app.component_instances.push ci
    app.save

    # test the regular code path
    p = OpenShift::ApplicationContainerProxy.find_available(:node_profile => "small", :gear => new_gear)
    assert p.id == @@server_id, "The expected node was not returned"
    
    # force the plugin to return an invalid node
    @@reurn_invalid_node = true
    begin
      p = OpenShift::ApplicationContainerProxy.find_available(:node_profile => "small", :gear => new_gear)
      assert true, "The exception was not raised even though the node selector plugin returned an invalid node: #{p.id}"
    rescue OpenShift::InvalidNodeException
      assert true, "The expected exception was raised when forcing the node selector plugin to return an invalid node"
    rescue Exception => ex
      assert false, "An unexpected exception was raised when forcing the node selector plugin to return an invalid node"
    end
  end

  test "default node selection plugin" do
    OpenShift::ApplicationContainerProxy.node_selector_plugin = nil
    p = OpenShift::ApplicationContainerProxy.find_available(:node_profile => "small")
    assert p.id == @@server_id, "The expected node was not returned"
  end

  test "known server identities" do
    servers = OpenShift::MCollectiveApplicationContainerProxy.known_server_identities(true)
    assert_equal 1, servers.length, "Expected exactly 1 node"
    assert_equal @@server_id, servers.first, "The expected node was not returned"
  end

  test "least preferred node selection" do
    OpenShift::ApplicationContainerProxy.node_selector_plugin = nil
    begin
      p = OpenShift::ApplicationContainerProxy.find_available(:node_profile => "small", :existing_gears_hosting => {@@server_id => 1})
      assert p.id == @@server_id, "The expected node was not returned"
    rescue OpenShift::NodeUnavailableException
      assert false, "The least preferred node was not selected and NodeUnavailableException was raised"
    end
  end

  test "restricted node selection" do
    OpenShift::ApplicationContainerProxy.node_selector_plugin = nil

    user = CloudUser.new(login: @@login)
    user.save
    domain = Domain.new(namespace: @@namespace, owner: user)
    domain.save
    app = Application.new(name: @@appname, domain: domain, ha: true, scalable: true)
    gi = GroupInstance.new({:custom_id => @@gi_id})
    app.group_instances.push gi
    app.group_overrides = @@group_overrides
    web_ci = ComponentInstance.new(cartridge_name: @@web_cart_name, component_name: @@web_comp_name, group_instance_id: gi._id)
    app.component_instances.push web_ci
    proxy_ci = ComponentInstance.new(cartridge_name: @@proxy_cart_name, component_name: @@proxy_comp_name, group_instance_id: gi._id)
    app.component_instances.push proxy_ci
    gear = Gear.new({:custom_id => @@gear_id, :group_instance => gi})
    gear.server_identity = @@server_id
    gear.sparse_carts.push proxy_ci._id
    app.gears.push gear
    new_gear = Gear.new({:custom_id => Moped::BSON::ObjectId.new, :group_instance => gi})
    app.gears.push new_gear
    app.save

    # test when multiple web proxies are allowed on the same node
    begin
      assert Rails.configuration.openshift[:allow_multiple_haproxy_on_node] == true, "Broker configuration for allowing multiple web proxies on the same node is not as expected"
      OpenShift::ApplicationContainerProxy.find_available(:node_profile => "small", :existing_gears_hosting => new_gear.server_identities_gears_map, :restricted_servers => new_gear.restricted_server_identities, :gear => new_gear)
    rescue OpenShift::NodeUnavailableException
      assert false, "NodeUnavailableException was raised even though multiple web proxies are allowed on the same node"
    end

    # test when multiple web proxies are not allowed on the same node
    # this is being simulated by setting the restricted server identities directly instead of relying on the gear
    begin
      OpenShift::ApplicationContainerProxy.find_available(:node_profile => "small", :existing_gears_hosting => new_gear.server_identities_gears_map, :restricted_servers => [@@server_id], :gear => new_gear)
    rescue OpenShift::NodeUnavailableException
      #this is expected
    else
      assert false, "NodeUnavailableException was not raised even though the node was restricted"
    end
  end

  def teardown
    super
    OpenShift::ApplicationContainerProxy.node_selector_plugin = nil

    CloudUser.where(login: @@login).delete
    Domain.where(canonical_namespace: @@namespace).delete
    Application.where(domain_namespace: @@namespace, canonical_name: @@appname).delete
    
    # reset the flag back to false
    @@reurn_invalid_node = false
  end

end
