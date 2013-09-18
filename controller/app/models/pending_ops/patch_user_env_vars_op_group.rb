class PatchUserEnvVarsOpGroup < PendingAppOpGroup

  field :user_env_vars, type: Array, default: []

  def elaborate(app)
    pending_ops.push(PatchUserEnvVarsOp.new(user_env_vars: user_env_vars))
  end
end
