class DeleteGroupInstanceOp < PendingAppOp

  field :group_instance_id, type: String

  # this op is being phased out - we perform this functionality in DeleteGearOp
  def execute
    begin
      group_instance = get_group_instance()
      application.atomic_update do
        if group_instance.gears.length == 0
          group_instance.all_component_instances.each{ |i| i.delete }
        end
        group_instance.delete
      end
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if group instance is already deleted
    end
  end

end
