class AddSshKeysUserOp < PendingUserOps

  field :keys_attrs, type: Array, default: []

  def execute
    ssh_keys = keys_attrs.map { |key_hash| UserSshKey.new.to_obj(key_hash, self.cloud_user) } 
    Application.accessible(self.cloud_user).each do |app|
      begin
        app.add_ssh_keys(ssh_keys)
      rescue Mongoid::Errors::DocumentNotFound
        # ignore if the application is already deleted
        raise unless Application.where("_id" => app._id).count == 0
      end
    end
  end
end
