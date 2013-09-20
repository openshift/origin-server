class UpdateAppConfigOpGroup < PendingAppOpGroup

  field :add_keys_attrs, type: Array, default: []
  field :remove_keys_attrs, type: Array, default: []
  field :add_env_vars, type: Array, default: []
  field :remove_env_vars, type: Array, default: []
  field :config, type: Hash, default: {}

  def elaborate(app)
    prereqs = {}
    unless (add_keys_attrs.nil? and remove_keys_attrs.nil? and add_env_vars.nil? and remove_env_vars.nil? and config.nil?)
      app.group_instances.each do |group_instance|
        group_instance_id = group_instance._id.to_s
        group_instance.gears.each do |gear|
          prereq = prereqs[gear._id.to_s].nil? ? [] : [prereqs[gear._id.to_s]]
          gear_id = gear._id.to_s
          #ops.push(PendingAppOp.new(op_type: :update_configuration, args: args.dup, prereq: prereq))
          pending_ops.push(UpdateAppConfigOp.new(add_keys_attrs: add_keys_attrs,
              remove_keys_attrs: remove_keys_attrs, add_env_vars: add_env_vars,
              remove_env_vars: remove_env_vars, config: config, group_instance_id: group_instance_id,
              gear_id: gear_id, prereq: prereq))
        end
      end
    end
  end

end
