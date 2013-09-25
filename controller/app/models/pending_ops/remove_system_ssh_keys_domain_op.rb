class RemoveSystemSshKeysDomainOp < PendingDomainOps

  field :keys_attrs, type: Array, default: []

  def execute(skip_node_ops=false)
    ssh_keys = keys_attrs.map { |key_hash| SystemSshKey.new.to_obj(key_hash) } 
    pending_apps.each { |app| app.remove_ssh_keys(nil, ssh_keys, self, skip_node_ops) }
  end
end
