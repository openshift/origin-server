class PatchUserEnvVarsOp < PendingAppOp

  field :user_env_vars, type: Array, default: []
  field :saved_user_env_vars, type: Array, default: []
  field :push_vars, type: Boolean, default: false

  def execute()
    result_io = ResultIO.new if result_io.nil?

    set_vars, unset_vars = Application.sanitize_user_env_variables(user_env_vars)
    if user_env_vars.present?
      # save overlapped user env vars for rollback
      existing_vars = pending_app_op_group.application.list_user_env_variables
      new_keys = user_env_vars.map {|ev| ev['name']}.compact
      overlapped_keys = existing_vars.keys & new_keys
      saved_vars = []
      overlapped_keys.each {|key| saved_vars << {'name' => key, 'value' => existing_vars[key]}}
      self.set(:saved_user_env_vars, saved_vars) unless saved_vars.empty?
    end
    
    result_io = pending_app_op_group.application.get_app_dns_gear.unset_user_env_vars(unset_vars, pending_app_op_group.application.get_gears_ssh_endpoint(true)) if unset_vars.present?
    result_io.append pending_app_op_group.application.get_app_dns_gear.set_user_env_vars(set_vars, pending_app_op_group.application.get_gears_ssh_endpoint(true)) if set_vars.present? or push_vars
    result_io
  end

  def rollback()
    set_vars, unset_vars = Application.sanitize_user_env_variables(user_env_vars)
    result_io = pending_app_op_group.application.get_app_dns_gear.unset_user_env_vars(set_vars, pending_app_op_group.application.get_gears_ssh_endpoint(true)) if set_vars.present?
    result_io.append pending_app_op_group.application.get_app_dns_gear.set_user_env_vars(saved_user_env_vars, pending_app_op_group.application.get_gears_ssh_endpoint(true)) if saved_user_env_vars.present?
  end

end
