class RemoveSshKeysUserOp < PendingUserOp

  field :keys_attrs, type: Array, default: []

  def execute
    ssh_keys = keys_attrs.map { |key_hash| UserSshKey.new.to_obj(key_hash, user) } 
    Application.accessible(user).each do |app|
      begin
        app.remove_ssh_keys(ssh_keys)
      rescue Mongoid::Errors::DocumentNotFound
        # ignore if the application is already deleted
        raise unless Application.where("_id" => app._id).count == 0
      end
    end

    ssh_keys.each do |ssh_key|
      user.ssh_keys.each { |key| key.delete if ssh_key.name == key.name }
    end
  end

  def rollback
    ssh_keys = keys_attrs.map { |key_hash| UserSshKey.new.to_obj(key_hash, user) }
    ssh_keys.each do |ssh_key|
      key_found = false
      user.ssh_keys.each do |user_ssh_key|
        if user_ssh_key.name == ssh_key.name
          key_found = true
          break
        end
      end
      user.ssh_keys << ssh_key unless key_found
    end

    Application.accessible(user).each do |app|
      begin
        app.add_ssh_keys(ssh_keys)
      rescue Mongoid::Errors::DocumentNotFound
        # ignore if the application is already deleted
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.inspect
      end
    end
  end

end
