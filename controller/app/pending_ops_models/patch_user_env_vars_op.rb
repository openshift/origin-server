class PatchUserEnvVarsOp < PendingAppOp

  field :user_env_vars, type: Array, default: []
  field :saved_user_env_vars, type: Array, default: []
  field :push_vars, type: Boolean, default: false

  def execute
    result_io = ResultIO.new
    gear = application.get_app_dns_gear
    unless gear.removed
      set_vars, unset_vars = Application.sanitize_user_env_variables(user_env_vars)
      if user_env_vars.present?
        # save overlapped user env vars for rollback
        existing_vars = application.list_user_env_variables
        new_keys = user_env_vars.map {|ev| ev['name']}.compact
        overlapped_keys = existing_vars.keys & new_keys
        saved_vars = []
        overlapped_keys.each {|key| saved_vars << {'name' => key, 'value' => existing_vars[key]}}
        self.set(:saved_user_env_vars, saved_vars) unless saved_vars.empty?
      end
 
      gears_endpoint = get_gears_ssh_endpoint(application) 
      result_io = gear.unset_user_env_vars(unset_vars, gears_endpoint) if unset_vars.present?
      result_io.append gear.set_user_env_vars(set_vars, gears_endpoint) if set_vars.present? or push_vars
    end
    result_io
  end

  def rollback
    result_io = ResultIO.new
    gear = nil
    
    begin 
      gear = application.get_app_dns_gear
    rescue OpenShift::UserException
      # if the head gear is missing, do not perform any operations and just return
      Rails.logger.info "DNS gear not found. Skipping rollback for PatchUserEnvVarsOp."
      return result_io
    end
    
    unless gear.nil? or gear.removed
      set_vars, unset_vars = Application.sanitize_user_env_variables(user_env_vars)
      gears_endpoint = get_gears_ssh_endpoint(application) 
      result_io = gear.unset_user_env_vars(set_vars, gears_endpoint) if set_vars.present?
      result_io.append gear.set_user_env_vars(saved_user_env_vars, gears_endpoint) if saved_user_env_vars.present?
    end
    result_io
  end

  def get_gears_ssh_endpoint(app)
    gears_endpoint = []
    app.gears.each do |gear|
      unless gear.removed
        gears_endpoint << "#{gear.uuid}@#{gear.server_identity}" unless gear.app_dns #skip app dns
      end
    end
    gears_endpoint
  end

end
