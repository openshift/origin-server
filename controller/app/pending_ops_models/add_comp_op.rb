class AddCompOp < PendingAppOp

  field :gear_id, type: String
  field :comp_spec, type: ComponentSpec
  field :init_git_url, type: String

  def execute
    gear = get_gear
    gear.add_component(get_component_instance, init_git_url)
  end

  def rollback
    gear = get_gear
    gear.remove_component(get_component_instance)
  end

end
