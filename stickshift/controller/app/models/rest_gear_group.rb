class RestGearGroup < StickShift::Model
  attr_accessor :uuid, :name, :gear_profile, :cartridges, :gears, :links

  def initialize(group_instance, gear_states, url, nolinks=false)
    app               = group_instance.app
    self.uuid         = group_instance.uuid
    self.name         = group_instance.name
    self.gear_profile = group_instance.node_profile
    self.gears        = group_instance.gears.map{ |gear| {:id => gear.uuid, :state => gear_states[gear.uuid] || 'unknown'} }
    self.cartridges   = group_instance.component_instances.map { |comp_inst| app.comp_instance_map[comp_inst].cart_properties.merge({:name => app.comp_instance_map[comp_inst].parent_cart_name}) }
    self.cartridges.delete_if{ |comp| comp[:name] == app.name }

    self.links = {
      "LIST_RESOURCES" => Link.new("List resources", "GET", URI::join(url, "domains/#{app.domain.namespace}/applications/#{app.name}/gear_groups/#{uuid}/resources")),
      "UPDATE_RESOURCES" => Link.new("Update resources", "PUT", URI::join(url, "domains/#{app.domain.namespace}/applications/#{app.name}/gear_groups/#{uuid}/resources"),[
        Param.new("storage", "integer", "The filesystem storage on each gear within the group in gigabytes")
      ])
    } unless nolinks
  end

  def to_xml(options={})
    options[:tag_name] = "gear_group"
    super(options)
  end
end
