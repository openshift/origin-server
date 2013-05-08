# Class representing a group of pending operations that must be executed in a transactional manner.
# @!attribute [r] pending_ops
#   @return [Array[PendingAppOp]] Array of pending operations that need to occur for this {Application}
# @!attribute [rw] parent_op_id
#   @return [Moped::BSON::ObjectId] ID of the {PendingDomainOps} operation that this operation is part of
# @!attribute [r] op_type
#   @return [Symbol] Group level operation type
# @!attribute [r] arguments
#   @return [Hash] Group level arguments hash
class PendingAppOpGroup
  include Mongoid::Document
  include Mongoid::Timestamps
  include TSort
  
  embedded_in :application, class_name: Application.name  
  field :op_type,           type: Symbol
  field :args,              type: Hash
  field :parent_op_id, type: Moped::BSON::ObjectId
  embeds_many :pending_ops, class_name: PendingAppOp.name
  field :num_gears_added,   type: Integer, default: 0
  field :num_gears_removed, type: Integer, default: 0
  
  field :num_gears_created, type: Integer, default: 0
  field :num_gears_destroyed, type: Integer, default: 0
  field :num_gears_rolled_back, type: Integer, default: 0
  field :user_agent, type: String, default: ""
  
  def initialize(attrs = nil, options = nil)
    parent_opid = nil
    if !attrs.nil? and attrs.has_key?(:parent_op)
      parent_opid = attrs[:parent_op]._id 
      attrs.delete(:parent_op)
    end
    super
    self.parent_op_id = parent_opid 
  end
  
  def eligible_rollback_ops
    # reloading the op_group reloads the application and then incorrectly reloads (potentially)
    # the op_group based on its position within the :pending_op_groups list
    # hence, reloading the application, and then fetching the op_group using the _id
    reloaded_app = Application.with(consistency: :strong).find_by(_id: application._id)
    op_group = reloaded_app.pending_op_groups.find_by(_id: self._id)
    self.pending_ops = op_group.pending_ops
    pending_ops.where(:state => :completed).select{|op| (pending_ops.where(:prereq => op._id.to_s, :state => :completed).count == 0)}
  end
  
  def eligible_ops
    # reloading the op_group reloads the application and then incorrectly reloads (potentially)
    # the op_group based on its position within the :pending_op_groups list
    # hence, reloading the application, and then fetching the op_group using the _id
    reloaded_app = Application.with(consistency: :strong).find_by(_id: application._id)
    op_group = reloaded_app.pending_op_groups.find_by(_id: self._id)
    self.pending_ops = op_group.pending_ops
    pending_ops.where(:state.ne => :completed).select{|op| pending_ops.where(:_id.in => op.prereq, :state.ne => :completed).count == 0}
  end
  
  def execute_rollback(result_io=nil)
    result_io = ResultIO.new if result_io.nil?
    
    while(pending_ops.where(:state => :completed).count > 0) do
      handle = RemoteJob.create_parallel_job
      parallel_job_ops = []
      
      eligible_rollback_ops.each do|op|
        use_parallel_job = false
        Rails.logger.debug "Rollback #{op.op_type}"
        case op.op_type
        when :create_group_instance
          group_instance = get_group_instance_for_rollback(op)
          group_instance.delete
        when :init_gear
          gear = get_gear_for_rollback(op)
          gear.delete
          application.save
        when :reserve_uid
          gear = get_gear_for_rollback(op)
          gear.unreserve_uid
        when :new_component
          component_instance = get_component_instance_for_rollback(op)
          application.component_instances.delete(component_instance)
        when :add_component
          gear = get_gear_for_rollback(op)
          component_instance = get_component_instance_for_rollback(op)
          result_io.append gear.remove_component(component_instance)
        when :create_gear
          gear = get_gear_for_rollback(op)
          result_io.append gear.destroy_gear(true)
          self.inc(:num_gears_rolled_back, 1)
        when :track_usage
          unless op.args["parent_user_id"].nil?
            storage_usage_type = (op.args["usage_type"] == UsageRecord::USAGE_TYPES[:addtl_fs_gb])
            tracked_storage = nil
            if storage_usage_type
              max_untracked_storage = (application.domain.owner.get_capabilities['max_untracked_addtl_storage_per_gear'] || 0)
              tracked_storage = op.args["additional_filesystem_gb"] - max_untracked_storage
            end
            if !storage_usage_type or (tracked_storage > 0)
              UsageRecord.untrack_usage(op.args["user_id"], op.args["gear_ref"], op.args["event"], op.args["usage_type"])
            end
          end
        when :register_dns
          gear = get_gear_for_rollback(op)
          gear.deregister_dns
        when :set_group_overrides
          application.group_overrides=op.saved_values["group_overrides"]
          application.save
        when :set_connections
          application.set_connections(op.saved_values["connections"])
        when :execute_connections
          application.execute_connections
        when :set_gear_additional_filesystem_gb
          gear = get_gear_for_rollback(op)
          gear.set_addtl_fs_gb(op.saved_values["additional_filesystem_gb"], handle)
          use_parallel_job = true
        when :add_alias
          gear = get_gear_for_rollback(op)
          result_io.append gear.remove_alias("abstract", op.args["fqdn"])
        when :remove_alias
          gear = get_gear_for_rollback(op)
          result_io.append gear.add_alias("abstract", op.args["fqdn"])
        when :add_ssl_cert
          gear = get_gear_for_rollback(op)
          result_io.append gear.remove_ssl_cert("abstract", op.args["fqdn"])
        when :remove_ssl_cert
          gear = get_gear_for_rollback(op)
          #TODO: Can't be undone since we do not store certificate info we cannot add it back in
          #result_io.append gear.add_ssl_cert("abstract", op.args["fqdn"])
        end
        
        if use_parallel_job 
          parallel_job_ops.push op
        else
          op.set(:state, :rolledback)
        end
      end
      
      if parallel_job_ops.length > 0
        RemoteJob.execute_parallel_jobs(handle)
        parallel_job_ops.each{ |op| op.state = :rolledback }
        self.application.save
      end
    end
  end
  
  def execute(result_io=nil)
    result_io = ResultIO.new if result_io.nil?    
    
    begin
      while(pending_ops.where(:state.ne => :completed).count > 0) do
        handle = RemoteJob.create_parallel_job
        parallel_job_ops = []
        
        eligible_ops.each do|op|
          use_parallel_job = false
          group_instance = application.group_instances.find(op.args["group_instance_id"]) unless op.args["group_instance_id"].nil? or op.op_type == :create_group_instance
          gear = group_instance.gears.find(op.args["gear_id"]) unless group_instance.nil? or op.args["gear_id"].nil? or op.op_type == :init_gear
          if op.args.has_key?("comp_spec")
            comp_name = op.args["comp_spec"]["comp"]
            cart_name = op.args["comp_spec"]["cart"]
            if op.op_type == :new_component
              component_instance = ComponentInstance.new(cartridge_name: cart_name, component_name: comp_name, group_instance_id: group_instance._id)
            else
              component_instance = application.component_instances.find_by(cartridge_name: cart_name, component_name: comp_name, group_instance_id: group_instance._id)
            end
          end

          Rails.logger.debug "Execute #{op.op_type}"
          case op.op_type
          when :create_group_instance
            application.group_instances.push(GroupInstance.new(custom_id: op.args["group_instance_id"]))
          when :init_gear
            group_instance.gears.push(Gear.new(custom_id: op.args["gear_id"], group_instance: group_instance, host_singletons: op.args["host_singletons"], app_dns: op.args["app_dns"]))
            application.save
          when :delete_gear
            gear.delete
            self.inc(:num_gears_destroyed, 1)
          when :destroy_group_instance
            group_instance.delete
          when :reserve_uid
            gear.reserve_uid
          when :unreserve_uid
            gear.unreserve_uid          
          when :expose_port
            job = gear.get_expose_port_job(cart_name)
            RemoteJob.add_parallel_job(handle, "expose-ports::#{component_instance._id.to_s}", gear, job)
            use_parallel_job = true
          when :new_component
            application.component_instances.push(component_instance)
          when :del_component
            application.component_instances.delete(component_instance)
          when :add_component
            result_io.append gear.add_component(component_instance, op.args["init_git_url"])
          when :post_configure_component
            result_io.append gear.post_configure_component(component_instance, op.args["init_git_url"])
          when :remove_component
            result_io.append gear.remove_component(component_instance)          
          when :create_gear
            result_io.append gear.create_gear
            raise OpenShift::NodeException.new("Unable to create gear", result_io.exitcode, result_io) if result_io.exitcode != 0
            self.inc(:num_gears_created, 1)
          when :track_usage
            unless op.args["parent_user_id"]
              storage_usage_type = (op.args["usage_type"] == UsageRecord::USAGE_TYPES[:addtl_fs_gb])
              tracked_storage = nil
              if storage_usage_type
                max_untracked_storage = (application.domain.owner.get_capabilities['max_untracked_addtl_storage_per_gear'] || 0)
                tracked_storage = op.args["additional_filesystem_gb"] - max_untracked_storage
              end
              if !storage_usage_type or (tracked_storage > 0)
                UsageRecord.track_usage(op.args["user_id"], op.args["app_name"], op.args["gear_ref"], op.args["event"], op.args["usage_type"],
                                        op.args["gear_size"], tracked_storage, op.args["cart_name"])
              end
            end
          when :register_dns          
            gear.register_dns
          when :deregister_dns          
            gear.deregister_dns          
          when :destroy_gear
            result_io.append gear.destroy_gear(true)
          when :start_component
            result_io.append gear.start(cart_name)
          when :stop_component
            if args.has_key?("force") and args["force"]==true
              result_io.append gear.force_stop(cart_name)
            else
              result_io.append gear.stop(cart_name)
            end
          when :restart_component
            result_io.append gear.restart(cart_name)
          when :reload_component_config
            result_io.append gear.reload_config(cart_name)
          when :tidy_component
            result_io.append gear.tidy(comp_name)
          when :update_configuration
            gear.update_configuration(op.args,handle)
            use_parallel_job = true
          when :update_namespace
            gear.update_namespace(op.args)
          when :add_broker_auth_key 
            job = gear.get_broker_auth_key_add_job(args["iv"], args["token"])
            RemoteJob.add_parallel_job(handle, "", gear, job)
            use_parallel_job = true
          when :remove_broker_auth_key
            job = gear.get_broker_auth_key_remove_job()
            RemoteJob.add_parallel_job(handle, "", gear, job)
            use_parallel_job = true
          when :complete_update_namespace
            component_instance.complete_update_namespace(op.args)
            self.application.save
          when :set_group_overrides
            application.group_overrides=op.args["group_overrides"]
            application.save
          when :set_connections
            application.set_connections(op.args["connections"])
          when :execute_connections
            application.execute_connections
          when :unsubscribe_connections
            application.unsubscribe_connections(op.args["sub_pub_info"])
          when :set_gear_additional_filesystem_gb
            gear.set_addtl_fs_gb(op.args["additional_filesystem_gb"], handle)
            use_parallel_job = true
          when :add_alias
            result_io.append gear.add_alias(op.args["fqdn"])
            self.application.aliases.push(Alias.new(fqdn: op.args["fqdn"]))
            self.application.save
          when :remove_alias
            result_io.append gear.remove_alias(op.args["fqdn"])
            a = self.application.aliases.find_by(fqdn: op.args["fqdn"])
            self.application.aliases.delete(a)
            self.application.save
          when :add_ssl_cert
            result_io.append gear.add_ssl_cert(op.args["ssl_certificate"], op.args["private_key"], op.args["fqdn"], op.args["pass_phrase"])
            a = self.application.aliases.find_by(fqdn: op.args["fqdn"])
            a.has_private_ssl_certificate = true
            a.certificate_added_at = Time.now
            self.application.save
          when :remove_ssl_cert
            result_io.append gear.remove_ssl_cert(op.args["fqdn"])
            a = self.application.aliases.find_by(fqdn: op.args["fqdn"])
            a.has_private_ssl_certificate = false
            a.certificate_added_at = nil
            self.application.save
          when :replace_all_ssh_keys
            job = gear.get_fix_authorized_ssh_keys_job(op.args["keys_attrs"])
            RemoteJob.add_parallel_job(handle, "", gear, job)
            use_parallel_job = true
          end
          
          if use_parallel_job 
            parallel_job_ops.push op
          else
            op.set(:state, :completed)
          end
        end
        if result_io.exitcode != 0
          if result_io.hasUserActionableError
            raise OpenShift::UserException.new("Unable to #{op.op_type.to_s.gsub("_"," ")}", result_io.exitcode, nil, result_io) 
          else
            raise OpenShift::NodeException.new("Unable to #{op.op_type.to_s.gsub("_"," ")}", result_io.exitcode, nil, result_io) 
          end
        end
      
        if parallel_job_ops.length > 0
          RemoteJob.execute_parallel_jobs(handle)
          RemoteJob.get_parallel_run_results(handle) do |tag, gear_id, output, status|
            if status==0 && tag.start_with?("expose-ports::")
              component_instance_id = tag[14..-1]
              application.component_instances.find(component_instance_id).process_properties(ResultIO.new(status, output, gear_id))
            end
          end
          parallel_job_ops.each{ |op| op.set(:state, :completed) }
          self.application.save
        end
      end
      unless self.parent_op_id.nil?
        reloaded_domain = Domain.with(consistency: :strong).find_by(_id: self.application.domain_id)
        reloaded_domain.pending_ops.find(self.parent_op_id).child_completed(self.application)
      end
    rescue Exception => e_orig
      Rails.logger.error e_orig.message
      Rails.logger.error e_orig.backtrace.inspect
      raise e_orig
    end
  end
  
  def get_group_instance_for_rollback(op)
    application.group_instances.find(op.args["group_instance_id"]) 
  end

  def get_gear_for_rollback(op)
    group_instance = get_group_instance_for_rollback(op)
    group_instance.gears.find(op.args["gear_id"])
  end

  def get_component_instance_for_rollback(op)
    component_instance = nil
    group_instance = get_group_instance_for_rollback(op)
    if op.args.has_key?("comp_spec")
      comp_name = op.args["comp_spec"]["comp"]
      cart_name = op.args["comp_spec"]["cart"]
      component_instance = application.component_instances.find_by(cartridge_name: cart_name, component_name: comp_name, group_instance_id: group_instance._id)
    end
    component_instance
  end
end
