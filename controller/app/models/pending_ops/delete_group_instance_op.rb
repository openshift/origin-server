class DeleteGroupInstanceOp < PendingAppOp

  field :group_instance_id, type: String

  def execute
    begin
      group_instance = get_group_instance()

      # delete all the gears within the group instance
      group_instance.gears.each do |gear|
        gear.delete
      end

      # delete all the component instances within the group instance
      group_instance.all_component_instances.each do |comp_inst|
        comp_inst.delete
      end

      group_instance.delete
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if group instance is already deleted
    end
  end

end
