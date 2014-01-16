require 'test_helper'

class NodeSelectionPluginTest < ActiveSupport::TestCase

  def setup
    @@login = "user#{gen_uuid[0..9]}"
    @@namespace = "ns#{gen_uuid[0..9]}"
    @@appname = "app#{gen_uuid[0..9]}"
    @@gi_id = Moped::BSON::ObjectId.new
    @@gear_id = Moped::BSON::ObjectId.new
    @@cart_name = "php-5.3"
    @@comp_name = "php-5.3"
    @@server_id = `oo-mco ping`.chomp.split(" ")[0]
  end

  def self.select_best_fit_node_impl(node_list, app_props, current_gears, comp_list, user_props, request_time)
    raise Exception.new("Node list is empty") if node_list.empty?
    raise Exception.new("Node expected: #{@@server_id}; Node found: #{node_list[0].name}") if node_list[0].name != @@server_id
    
    raise Exception.new("Application properties not specified") if app_props.nil?
    raise Exception.new("Application name mismatch") if app_props.name != @@appname

    raise Exception.new("Current gears list is empty") if current_gears.empty?
    raise Exception.new("Current gear count mismatch") if current_gears.length != 1
    raise Exception.new("Current gear name mismatch") if current_gears[0].name != @@gear_id.to_s
    raise Exception.new("Current gear server mismatch") if current_gears[0].server != @@server_id
    
    raise Exception.new("User properties not specified") if user_props.nil?
    raise Exception.new("User login mismatch") if user_props.login != @@login
    
    raise Exception.new("Component instances not specified") if comp_list.empty?
    raise Exception.new("Component count mismatch") if comp_list.length != 1
    raise Exception.new("Cartridge name mismatch") if comp_list[0].cartridge_name != @@cart_name
    raise Exception.new("Component name mismatch") if comp_list[0].component_name != @@comp_name

    raise Exception.new("Request time not specified") if request_time.nil?

    return NodeProperties.new("serverid")
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
    ci = ComponentInstance.new(cartridge_name: @@cart_name, component_name: @@comp_name, group_instance_id: gi._id)
    app.component_instances.push ci
    app.save
    
    p = OpenShift::ApplicationContainerProxy.find_available("small", nil, nil, new_gear)
    assert p.id == "serverid", "The expected node was not returned"
  end

  test "default node selection plugin" do
    OpenShift::ApplicationContainerProxy.node_selector_plugin = nil
    p = OpenShift::ApplicationContainerProxy.find_available("small")
    assert p.id == @@server_id, "The expected node was not returned"
  end

  def teardown
    super
    OpenShift::ApplicationContainerProxy.node_selector_plugin = nil
    
    CloudUser.where(login: @@login).delete
    Domain.where(canonical_namespace: @@namespace).delete
    Application.where(domain_namespace: @@namespace, canonical_name: @@appname).delete
  end

end
