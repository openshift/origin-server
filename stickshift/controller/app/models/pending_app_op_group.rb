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
  field :num_gears_removed,   type: Integer, default: 0
  
  def initialize(attrs = nil, options = nil)
    if !attrs.nil? and attrs.has_key?(:parent_op)
      self.parent_op_id = attrs[:parent_op]._id 
      attrs.delete(:parent_op)
    end
    super
  end
  
  def eligible_ops
    self.reload
    pending_ops.where(:state.ne => :completed).select{|op| pending_ops.where(:_id.in => op.prereq, :state.ne => :completed).count == 0}
  end
  
  def execute
    while(pending_ops.where(:state.ne => :completed).count > 0) do
      eligible_ops.each do|op|
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
        
        
        case op.op_type
        when :create_group_instance
          application.group_instances.push(GroupInstance.new(custom_id: op.args["group_instance_id"]))
        when :init_gear
          group_instance.gears.push(Gear.new(custom_id: op.args["gear_id"], group_instance: group_instance, host_singletons: op.args["host_singletons"], app_dns: op.args["app_dns"]))
          application.save
        when :delete_gear
          gear.delete
        when :destroy_group_instance
          group_instance.delete
        when :reserve_uid
          gear.reserve_uid
        when :unreserve_uid
          gear.unreserve_uid          
        when :new_component
          application.component_instances.push(component_instance)
        when :del_component
          application.component_instances.delete(component_instance)
        when :add_component
          gear.add_component(component_instance)
        when :remove_component
          gear.remove_component(component_instance)          
        when :create_gear
          gear.create
        when :register_dns          
          gear.register_dns
        when :deregister_dns          
          gear.deregister_dns          
        when :destroy_gear
          gear.destroy_gear          
        when :update_configuration
          gear.update_configuration(op.args)
        when :set_connections
          application.set_connections(op.args["connections"])
        when :execute_connections
          application.execute_connections
        end        
        op.set(:state, :completed)
      end
    end
  end
end