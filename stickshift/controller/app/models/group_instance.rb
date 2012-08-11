class GroupInstance
  include Mongoid::Document
  embedded_in :application, class_name: Application.name
  
  field :min, type: Integer
  field :max, type: Integer
  field :gear_profile, type: String  
  field :component_instances, type: Array
  field :singleton_instances, type: Array
  embeds_many :gears, class_name: Gear.name
  
  def to_hash
    comps = component_instances.map{ |c| application.component_instances.find(c).to_hash } + singleton_instances.map{ |c| application.component_instances.find(c).to_hash }
    {component_instances: comps, scale: {min: min, max: max, current: gears.length}, _id: _id}
  end
end
