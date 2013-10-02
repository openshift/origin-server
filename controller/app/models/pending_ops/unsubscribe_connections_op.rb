class UnsubscribeConnectionsOp < PendingAppOp

  field :sub_pub_info, type: Hash, default: {}
  
  def execute
    app = pending_app_op_group.application

    if app.scalable and sub_pub_info
      Rails.logger.debug "Running unsubscribe connections"
      handle = RemoteJob.create_parallel_job
      sub_pub_info.values.each do |to, from|
        sub_inst = nil
        begin
          sub_inst = app.component_instances.find_by(cartridge_name: to["cart"], component_name: to["comp"])
        rescue Mongoid::Errors::DocumentNotFound
          #ignore
        end
        next if sub_inst.nil?
        sub_ginst = app.group_instances.find(sub_inst.group_instance_id)
        pub_cart_name = from["cart"]
        tag = sub_inst._id.to_s

        sub_ginst.get_gears(sub_inst).each do |gear|
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
