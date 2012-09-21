class RestGearGroup < StickShift::Model
  attr_accessor :uuid, :name, :gear_profile, :cartridges, :gears, :storage, :min_scale, :max_scale, :links

  def initialize(group_instance, gear_states, url, nolinks=false)
    app               = group_instance.app
    self.uuid         = group_instance.uuid
    self.name         = group_instance.name
    self.gear_profile = group_instance.node_profile
    self.gears        = group_instance.gears.map{ |gear| {:id => gear.uuid, :state => gear_states[gear.uuid] || 'unknown'} }
    self.cartridges   = group_instance.component_instances.map { |comp_inst| app.comp_instance_map[comp_inst].cart_properties.merge({:name => app.comp_instance_map[comp_inst].parent_cart_name}) }
    self.cartridges.delete_if{ |comp| comp[:name] == app.name }
    self.storage      = group_instance.get_quota[:storage]
    self.max_scale = group_instance.max
    self.min_scale = group_instance.min
    self.links = {
      "GET" => Link.new("Get gear group", "GET", URI::join(url, "domains/#{app.domain.namespace}/applications/#{app.name}/gear_groups/#{uuid}")),
      "UPDATE" => Link.new("Update gear group", "PUT", URI::join(url, "domains/#{app.domain.namespace}/applications/#{app.name}/gear_groups/#{uuid}"),[
        Param.new("storage", "integer", "The filesystem storage on each gear within the group in gigabytes")
      ])
    } unless nolinks
  end

  def to_xml(options={})
    options[:tag_name] = "gear_group"
    super(options)
  end
end
