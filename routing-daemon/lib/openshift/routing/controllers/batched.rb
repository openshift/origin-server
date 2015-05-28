require 'rubygems'
require 'parseconfig'
require 'openshift/routing/controllers/load_balancer'
require 'openshift/routing/models/load_balancer'

module OpenShift

  # == Batched Load Balancer Controller
  #
  # Represents a load balancer for the OpenShift Enterprise installation.
  # On initalization, the object queries the configured load balancer for
  # the configured pools and builds a table of Pool objects.
  #
  class BatchedLoadBalancerController < LoadBalancerController

    # == Pool object
    #
    # Represents the pool.  On initialization, the object queries the load balancer
    # using the LoadBalancerModel object provided as lb_model to obtain the members
    # of the pool named by pool_name.  These pool members are stored in @members
    # using one string of the form address:port to represent each pool member.
    #
    class Pool < LoadBalancerController::Pool
      def initialize lb_controller, lb_model, pool_name
        @lb_controller, @lb_model, @name = lb_controller, lb_model, pool_name
        @members = @lb_model.get_pool_members pool_name
        @aliases = @lb_model.get_pool_aliases pool_name
      end

      # Add a member to the object's internal list of members.  This method does not
      # update the load balancer; use the update method to force an update.
      def add_member address, port
        member = address + ':' + port.to_s
        raise LBControllerException.new "Adding gear #{member} to pool #{@name}, of which the gear is already a member" if @members.include? member
        @members.push member
        pending = [self.name, [address, port.to_s]]
        @lb_controller.pending_add_member_ops.push pending unless @lb_controller.pending_delete_member_ops.delete pending
      end

      # Remove a member from the object's internal list of members.  This method does
      # not update the load balancer; use the update method to force an update.
      def delete_member address, port
        member = address + ':' + port.to_s
        raise LBControllerException.new "Deleting gear #{member} from pool #{@name}, of which the gear is not a member" unless @members.include? member
        @members.delete member
        pending = [self.name, [address, port.to_s]]
        @lb_controller.pending_delete_member_ops.push pending unless @lb_controller.pending_add_member_ops.delete pending
      end

      def get_aliases
        @aliases
      end

      def add_alias alias_str
        raise LBControllerException.new "Adding alias #{alias_str} to pool #{@name}, which already has the alias" if @aliases.include? alias_str
        @aliases.push alias_str
        @lb_model.add_pool_alias @name, alias_str
      end

      def delete_alias alias_str
        raise LBControllerException.new "Deleting non-existent alias #{alias_str} from pool #{@name}" unless @aliases.include? alias_str
        @aliases.delete alias_str
        @lb_model.delete_pool_alias @name, alias_str
      end

      def add_monitor monitor_name
        @lb_model.add_pool_monitor @name, monitor_name
      end

      def delete_monitor monitor_name
        @lb_model.delete_pool_monitor @name, monitor_name
      end

      def get_monitors
        @lb_model.get_pool_monitors @name
      end
    end

    def add_ssl alias_str, ssl_cert, private_key
    end

    def remove_ssl alias_str
    end

    attr_reader :pending_add_member_ops, :pending_delete_member_ops

    def create_pool pool_name, monitor_name=nil
      raise LBControllerException.new "Pool already exists: #{pool_name}" if pools.include? pool_name

      @lb_model.create_pools [pool_name], [monitor_name]

      @pools[pool_name] = Pool.new self, @lb_model, pool_name
    end

    def delete_pool pool_name
      raise LBControllerException.new "Pool not found: #{pool_name}" unless pools.include? pool_name

      update # in case we have pending delete operations for the pool.

      @lb_model.delete_pools [pool_name]

      @pools.delete pool_name
    end

    def create_monitor monitor_name, path, up_code, type, interval, timeout
      @logger.debug "Creating monitor #{monitor_name}, #{path}, #{up_code}, #{type}, #{interval}, #{timeout}"
      if monitors.include? monitor_name
        @logger.debug "Monitor #{monitor_name} already exists in cached list of monitors; clearing cache to force a refresh..."
        @monitors = nil
        raise LBControllerException.new "Monitor already exists: #{monitor_name}" if monitors.include? monitor_name
      end

      @lb_model.create_monitor monitor_name, path, up_code, type, interval, timeout

      @monitors.push monitor_name
    end

    def delete_monitor monitor_name, pool_name, type
      @logger.debug "Deleting monitor #{monitor_name}, #{pool_name}, #{type}"
      unless monitors.include? monitor_name
        @logger.debug "Monitor #{monitor_name} does not exist in cached list of monitors; clearing cache to force a refresh..."
        @monitors = nil
        raise LBControllerException.new "Monitor not found: #{monitor_name}" unless monitors.include? monitor_name
      end

      # we assume the types won't be modified at runtime
      @lb_model.delete_monitor monitor_name, type if monitors.include? monitor_name

      @monitors.delete monitor_name
    end

    def update
      adds = @pending_add_member_ops.inject(Hash.new {Array.new}) {|h,(k,v)| h[k] = h[k].push v; h}
      dels = @pending_delete_member_ops.inject(Hash.new {Array.new}) {|h,(k,v)| h[k] = h[k].push v; h}
      @lb_model.add_pool_members adds.keys, adds.values unless adds.empty?
      @lb_model.delete_pool_members dels.keys, dels.values unless dels.empty?
      @pending_add_member_ops = []
      @pending_delete_member_ops = []
      @lb_model.update if @lb_model.respond_to?(:update)
    end

    def initialize lb_model_class, logger, cfgfile
      @logger = logger

      @logger.info 'Initializing batched controller...'

      @lb_model = lb_model_class.new @logger, cfgfile
      @lb_model.authenticate

      @pools = Hash[@lb_model.get_pool_names.map {|pool_name| [pool_name, Pool.new(self, @lb_model, pool_name)]}]
      @monitors = @lb_model.get_monitor_names

      @pending_add_member_ops = []
      @pending_delete_member_ops = []
    end
  end

end
