class AddCompOp < PendingAppOp

  field :gear_id, type: String
  field :comp_spec, type: ComponentSpec
  field :init_git_url, type: String
  field :skip_rollback, type: Boolean

  def execute
    gear = get_gear
    gear.add_component(get_component_instance, init_git_url)
  end

  def rollback
    result_io = nil
    unless skip_rollback
      gear = get_gear
      # do not check for gear.removed in here
      # it is being checked inside the gear.remove_component method
      # since, in addition to a node operation, this also involves a mongo update for sparse carts
      result_io = gear.remove_component(get_component_instance)
    end
    result_io
  end

end
