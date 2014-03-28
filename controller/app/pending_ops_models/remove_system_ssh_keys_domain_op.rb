class RemoveSystemSshKeysDomainOp < PendingDomainOps

  field :keys_attrs, type: Array, default: []

  def execute
    ssh_keys = keys_attrs.map { |key_hash| SystemSshKey.new.to_obj(key_hash) } 
    pending_apps.each { |app| app.remove_ssh_keys(ssh_keys, self) }
  end
end
