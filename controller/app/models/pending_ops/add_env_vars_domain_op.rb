class AddEnvVarsDomainOp < PendingDomainOps

  field :variables, type: Array

  def execute(skip_node_ops=false)
    pending_apps.each { |app| app.add_env_variables(variables, self, skip_node_ops) }
  end
end
