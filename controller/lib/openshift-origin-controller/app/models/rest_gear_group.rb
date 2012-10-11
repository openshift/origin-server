class RestGearGroup < OpenShift::Model
  attr_accessor :uuid, :name, :gear_profile, :cartridges, :gears, :scales_from, :scales_to, :links, :base_gear_storage, :additional_gear_storage

  def initialize(group_instance, gear_states, url, nolinks=false)
    app               = group_instance.app
    self.uuid         = group_instance.uuid
    self.name         = group_instance.name
    self.gear_profile = group_instance.node_profile
    self.gears        = group_instance.gears.map{ |gear| {:id => gear.uuid, :state => gear_states[gear.uuid] || 'unknown'} }
    self.cartridges   = group_instance.component_instances.map { |comp_inst| app.comp_instance_map[comp_inst].cart_properties.merge({:name => app.comp_instance_map[comp_inst].parent_cart_name}) }
    self.cartridges.delete_if{ |comp| comp[:name] == app.name }
    storage = group_instance.get_quota
    self.base_gear_storage = storage["base_gear_storage"]
    self.additional_gear_storage = storage["additional_gear_storage"]
    self.scales_to = group_instance.max
    self.scales_from = group_instance.min
    self.links = {
      "GET" => Link.new("Get gear group", "GET", URI::join(url, "domains/#{app.domain.namespace}/applications/#{app.name}/gear_groups/#{uuid}"))
    } unless nolinks
  end

  def to_xml(options={})
    options[:tag_name] = "gear_group"
    super(options)
  end
end
