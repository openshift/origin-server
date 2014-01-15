class DeleteGroupInstanceOp < PendingAppOp

  field :group_instance_id, type: String

  # this op is being phased out - we perform this functionality in DeleteGearOp
  def execute
    begin
      group_instance = get_group_instance()
      group_instance.delete
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if group instance is already deleted
    end
  end

end
