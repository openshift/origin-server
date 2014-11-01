class UnsubscribeConnectionsOp < PendingAppOp

  field :sub_pub_info, type: Hash, default: {}

  def execute
    unless is_app_delete_op_group?
      if application.scalable and sub_pub_info.present?
        Rails.logger.debug "Running unsubscribe connections"
        handle = RemoteJob.create_parallel_job
        sub_pub_info.values.each do |to, from|
          sub_inst = nil
          sub_ginst = nil
          begin
            # the publishing (from) component instance is no longer in the app, since it has been deleted already
            pub_cart_name = ComponentSpec.demongoize(from).cartridge_name
            sub_inst = application.find_component_instance_for(ComponentSpec.demongoize(to))
            sub_ginst = application.group_instances.find(sub_inst.group_instance_id)
          rescue Mongoid::Errors::DocumentNotFound
            next
          end

          tag = sub_inst._id.to_s

          sub_inst.gears.each do |gear|
            unless gear.removed
              job = gear.get_unsubscribe_job(sub_inst, pub_cart_name)
              RemoteJob.add_parallel_job(handle, tag, gear, job)
            end
          end
        end
        RemoteJob.execute_parallel_jobs(handle)
        RemoteJob.get_parallel_run_results(handle) do |tag, gear_id, output, status|
          if status != 0
            Rails.logger.error "Unsubscribe Connection event failed:: tag: #{tag}, gear_id: #{gear_id},"\
                               "output: #{output}, status: #{status}"
          end
        end
      end
    end
  end

end
