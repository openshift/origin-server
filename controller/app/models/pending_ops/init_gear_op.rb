class InitGearOp < PendingAppOp

  field :gear_id, type: String
  field :group_instance_id, type: String
  field :host_singletons, type: Boolean, default: false
  field :app_dns, type: Boolean, default: false

  def execute(skip_node_ops=false)
    group_instance = get_group_instance()
    group_instance.gears.push(Gear.new(custom_id: gear_id, group_instance: group_instance, host_singletons: host_singletons, app_dns: app_dns))
    pending_app_op_group.application.save
  end
  
  def rollback(skip_node_ops=false)
    begin
      gear = get_gear()
      gear.delete
      pending_app_op_group.application.save
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if gear is already deleted
    end
  end

end
