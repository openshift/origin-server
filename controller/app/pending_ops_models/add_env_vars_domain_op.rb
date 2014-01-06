class AddEnvVarsDomainOp < PendingDomainOps

  field :variables, type: Array

  def execute
    pending_apps.each { |app| app.add_env_variables(variables, self) }
  end
end
