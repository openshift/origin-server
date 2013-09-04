class ApplicationConfigValidator < ActiveModel::Validator
  def validate(record)
    application_config = record.config
    if application_config.nil?
      record.errors.add(:config, {:message => "Application config is nil", :exit_code => -1})
    else
      ["auto_deploy", "deployment_branch", "keep_deployments", "deployment_type"].each do |key|
        record.errors.add(:config, {:message => "Missing #{key} config", :exit_code => -1}) if application_config[key].nil?
      end
    end
  end
end
