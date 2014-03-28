class CreateGroupInstanceOp < PendingAppOp

  field :group_instance_id, type: String

  def rollback
    begin
      group_instance = get_group_instance()
      group_instance.delete
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if group instance is already deleted
    end
  end

end
