class UpdateAppConfigOpGroup < PendingAppOpGroup

  field :add_keys_attrs, type: Array, default: []
  field :remove_keys_attrs, type: Array, default: []
  field :add_env_vars, type: Array, default: []
  field :remove_env_vars, type: Array, default: []
  field :config, type: Hash, default: {}

  def elaborate(app)
    prereqs = {}
    unless (add_keys_attrs.nil? and remove_keys_attrs.nil? and add_env_vars.nil? and remove_env_vars.nil? and config.nil?)
      app.gears.each do |gear|
        gear_id = gear._id.to_s
        prereq = prereqs[gear_id].nil? ? [] : [prereqs[gear_id]]
        pending_ops.push(UpdateAppConfigOp.new(add_keys_attrs: add_keys_attrs,
            remove_keys_attrs: remove_keys_attrs, add_env_vars: add_env_vars,
            remove_env_vars: remove_env_vars, config: config, gear_id: gear_id, prereq: prereq))
      end
    end
  end

end
