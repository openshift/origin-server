class DeleteGearOp < PendingAppOp

  field :gear_id, type: String

  def execute
    group_instance = nil
    begin
      gear = get_gear()
      group_instance = gear.group_instance
      gear.delete
      pending_app_op_group.inc(:num_gears_destroyed, 1)
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if gear is already deleted
    end

    begin
      # if the group_instance has no more gears, then delete it and its component instances
      if group_instance and group_instance.gears.length == 0
        group_instance.all_component_instances.each do |comp_inst|
          comp_inst.delete
        end

        group_instance.delete
      end  
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if the group instance is already deleted
    end
  end

end
