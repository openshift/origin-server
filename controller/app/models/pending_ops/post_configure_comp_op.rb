class PostConfigureCompOp < PendingAppOp

  field :group_instance_id, type: String
  field :gear_id, type: String
  field :comp_spec, type: Hash, default: {}
  field :init_git_url, type: String

  def execute()
    gear = get_gear()
    component_instance = get_component_instance()
    result_io = gear.post_configure_component(component_instance, init_git_url)
    result_io
  end

end
