class RemoveCompOp < PendingAppOp

  field :gear_id, type: String
  field :comp_spec, type: ComponentSpec, default: {}

  def execute
    gear = get_gear
    component_instance = get_component_instance

    begin
      result_io = gear.remove_component(component_instance)
    ensure
      # setting the rollback_blocked flag to true since after this point, the operation is not reversible
      # even in case of failure, once a call is made to the node, there is no saying what damage has been done already
      self.pending_app_op_group.set :rollback_blocked, true
    end

    result_io
  end

end
