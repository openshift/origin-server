class AddSshKeysUserOp < PendingUserOps

  field :keys_attrs, type: Array, default: []

  def execute(skip_node_ops=false)
    ssh_keys = keys_attrs.map { |key_hash| UserSshKey.new.to_obj(key_hash) } 
    Application.accessible(self.cloud_user).each{ |app| app.add_ssh_keys(self.cloud_user._id, ssh_keys, nil, skip_node_ops) }
  end
end
