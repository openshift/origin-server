class RemoveSshKeysUserOp < PendingUserOps

  field :keys_attrs, type: Array, default: []

  def execute
    ssh_keys = keys_attrs.map { |key_hash| UserSshKey.new.to_obj(key_hash, self.cloud_user) } 
    Application.accessible(self.cloud_user).each{ |app| app.remove_ssh_keys(ssh_keys) }
  end
end
