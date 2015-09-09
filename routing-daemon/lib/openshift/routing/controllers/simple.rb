require 'rubygems'
require 'parseconfig'
require 'openshift/routing/controllers/load_balancer'
require 'openshift/routing/models/load_balancer'

module OpenShift

  # == Simple Load Balancer Controller
  #
  # Represents a load balancer for the OpenShift Enterprise installation.
  # On initalization, the object queries the configured load balancer for
  # the configured pools and builds a table of Pool objects.
  #
  class SimpleLoadBalancerController < LoadBalancerController

    # == Pool object
    #
    # Represents the pool.  On initialization, the object queries the load balancer
    # to obtain the members of the pool named by pool_name.  These pool members are
    # stored in @members using one string of the form address:port to represent each
    # pool member.
    class Pool < LoadBalancerController::Pool
      def initialize lb_controller, lb_model, pool_name
        @lb_controller, @lb_model, @name = lb_controller, lb_model, pool_name
        @members = @lb_model.get_pool_members pool_name
        @aliases = @lb_model.get_pool_aliases pool_name
        @certs = @lb_model.get_pool_certificates pool_name
      end

      def add_member address, port
        member = address + ':' + port.to_s
        @members.push member
        @lb_model.add_pool_member @name, address, port
      end

      def delete_member address, port
        member = address + ':' + port.to_s
        @members.delete member
        @lb_model.delete_pool_member @name, address, port
      end

      def get_aliases
        @aliases
      end

      def add_alias alias_str
        @aliases.push alias_str
        @lb_model.add_pool_alias @name, alias_str
      end

      def delete_alias alias_str
        @aliases.delete alias_str
        @lb_model.delete_pool_alias @name, alias_str
      end

      def get_certificates
        @certs
      end

      def add_ssl alias_str, ssl_cert, private_key
        @certs.push alias_str
        @lb_model.add_ssl @name, alias_str, ssl_cert, private_key
      end

      def remove_ssl alias_str
        @certs.delete alias_str
        @lb_model.remove_ssl @name, alias_str
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

    def create_pool pool_name, monitor_name=nil
      raise LBControllerException.new "Pool already exists: #{pool_name}" if pools.include? pool_name

      @lb_model.create_pools [pool_name], [monitor_name]

      pools[pool_name] = Pool.new self, @lb_model, pool_name
    end

    def delete_pool pool_name
      raise LBControllerException.new "Pool not found: #{pool_name}" unless pools.include? pool_name
      # Making a copy because we are deleting elements
      aliases = Array.new(pools[pool_name].get_aliases)
      aliases.each {|a| pools[pool_name].delete_alias a}
      pools[pool_name].get_certificates.each {|a| pools[pool_name].remove_ssl a}

      @lb_model.delete_pools [pool_name]

      pools.delete pool_name
    end

    def create_monitor monitor_name, path, up_code, type, interval, timeout
      @logger.debug "Creating monitor #{monitor_name}, #{path}, #{up_code}, #{type}, #{interval}, #{timeout}"
      if monitors.include? monitor_name
        @logger.debug "Monitor #{monitor_name} already exists in cached list of monitors; clearing cache to force a refresh..."
        @monitors = nil
        raise LBControllerException.new "Monitor already exists: #{monitor_name}" if monitors.include? monitor_name
      end

      @lb_model.create_monitor monitor_name, path, up_code, type, interval, timeout

      monitors.push monitor_name
    end

    def delete_monitor monitor_name, pool_name, type
      @logger.debug "Deleting monitor #{monitor_name}, #{pool_name}, #{type}"
      unless monitors.include? monitor_name
        @logger.debug "Monitor #{monitor_name} does not exist in cached list of monitors; clearing cache to force a refresh..."
        @monitors = nil
        raise LBControllerException.new "Monitor not found: #{monitor_name}" unless monitors.include? monitor_name
      end

      @lb_model.delete_monitor monitor_name, type

      monitors.delete monitor_name
    end

    def pools
      @pools ||= begin
        @logger.info "Requesting list of pools from load balancer..."
        Hash[@lb_model.get_pool_names.map {|pool_name| [pool_name, Pool.new(self, @lb_model, pool_name)]}]
      end
    end

    def monitors
      @monitors ||= begin
        @logger.info "Requesting list of monitors from load balancer..."
        @lb_model.get_monitor_names
      end
    end

    def initialize lb_model_class, logger, cfgfile
      @logger = logger

      @logger.info 'Initializing controller...'

      @lb_model = lb_model_class.new @logger, cfgfile
      @lb_model.authenticate
    end
  end

end
