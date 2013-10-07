class ApplicationConfigValidator < ActiveModel::Validator
  def validate(record)
    application_config = record.config
    if application_config.nil?
      record.errors.add(:config, {:message => "Application config is nil", :exit_code => -1})
    else
      ["auto_deploy", "deployment_branch", "keep_deployments", "deployment_type"].each do |key|
        record.errors.add(:config, {:message => "Missing #{key} config", :exit_code => -1}) if application_config[key].nil?
      end
      #individual field validation
      if application_config["auto_deploy"] and not [true, false].include? application_config["auto_deploy"]
        record.errors.add(:config, {:message => "Invalid value '#{application_config["auto_deploy"]}' for auto_deploy.  Acceptable values are true or false", :exit_code => -1}) 
      end
      if application_config["deployment_type"] and not Application::DEPLOYMENT_TYPES.include? application_config["deployment_type"]
        record.errors.add(:config, {:message => "Invalid deployment type: #{application_config["deployment_type"]}. Acceptable values are: #{Application::DEPLOYMENT_TYPES.join(", ")}", :exit_code => -1}) 
      end
      if application_config["keep_deployments"] and application_config["keep_deployments"] < 1
        record.errors.add(:config, {:message => "Invalid number of deployments to keep: #{application_config["keep_deployments"]}. Keep deployments must be greater than 0.", :exit_code => -1}) 
      end
      if application_config["deployment_branch"] and application_config["deployment_branch"].length > 256 
        record.errors.add(:config, {:message => "Invalid deployment_branch: #{application_config["deployment_branch"]}. Deployment branches are limited to 256 characters", :exit_code => -1})
      end
    end
  end
end
