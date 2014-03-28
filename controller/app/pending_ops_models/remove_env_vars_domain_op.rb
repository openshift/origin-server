class RemoveEnvVarsDomainOp < PendingDomainOps

  field :variables, type: Array

  def execute
    pending_apps.each { |app| app.remove_env_variables(variables, self) }
  end
end
