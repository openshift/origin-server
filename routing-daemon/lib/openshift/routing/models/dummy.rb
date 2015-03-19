require 'openshift/routing/models/load_balancer'

module OpenShift

  # == Example routing model class
  #
  # Implements the LoadBalancerModel interface with dummy methods that just log
  # output representing actions that a normal implementation would perform,
  # without actually taking action against a load balancer.
  #
  class DummyLoadBalancerModel < LoadBalancerModel

    def get_pool_names
      @logger.debug "get pool names"
      []
    end

    def create_pool pool_name, monitor_name
      @logger.debug "create pool #{pool_name} with monitor #{monitor_name}"
      [] # If using AsyncLoadBalancerController, return an array of jobids.
    end

    def delete_pool pool_name
      @logger.debug "delete pool #{pool_name}"
      [] # If using AsyncLoadBalancerController, return an array of jobids.
    end

    def get_monitor_names
      @logger.debug "get monitor names"
      [] # Return an array of String representing monitors.
    end

    def create_monitor monitor_name, path, up_code, type, interval, timeout
      @logger.debug "create monitor #{monitor_name} using path #{path} with type #{type} and interval #{interval} and timeout #{timeout} where '#{up_code}' means up"
      [] # If using AsyncLoadBalancerController, return an array of jobids.
    end

    def delete_monitor monitor_name, type
      @logger.debug "delete monitor #{monitor_name} of type #{type}"
      [] # If using AsyncLoadBalancerController, return an array of jobids.
    end

    def add_pool_monitor pool_name, monitor_name
      @logger.debug "add monitor #{monitor_name} to pool #{pool_name}"
      [] # If using AsyncLoadBalancerController, return an array of jobids.
    end

    def delete_pool_monitor pool_name, monitor_name
      @logger.debug "delete monitor #{monitor_name} from pool #{pool_name}"
      [] # If using AsyncLoadBalancerController, return an array of jobids.
    end

    def get_pool_monitors pool_name
      @logger.debug "get monitors of pool #{pool_name}"
      [] # If using AsyncLoadBalancerController, return an array of jobids.
    end

    def get_pool_certificates pool_name
      @logger.debug "get pool certificates #{pool_name}"
      [] # Return an array of String representing certificates.
    end

    def get_pool_members pool_name
      @logger.debug "get members of pool #{pool_name}"
      [] # Return an array of String representing pool members.
    end

    def get_active_pool_members
      @logger.debug "get active members of pool #{pool_name}"
      [] # Return an array of String representing pool members.
    end

    def add_pool_member pool_name, address, port
      @logger.debug "add member #{address}:#{port} to pool #{pool_name}"
      [] # If using AsyncLoadBalancerController, return an array of jobids.
    end

    def delete_pool_member pool_name, address, port
      @logger.debug "delete member #{address}:#{port} from pool #{pool_name}"
      [] # If using AsyncLoadBalancerController, return an array of jobids.
    end

    def get_pool_aliases
      @logger.debug "get aliases of pool #{pool_name}"
      [] # Return an array of String representing pool aliases.
    end

    def add_pool_alias pool_name, alias_str
      @logger.debug "add alias #{alias_str} to pool #{pool_name}"
      [] # If using AsyncLoadBalancerController, return an array of jobids.
    end

    def delete_pool_alias pool_name, alias_str
      @logger.debug "delete alias #{alias_str} from pool #{pool_name}"
      [] # If using AsyncLoadBalancerController, return an array of jobids.
    end

    def add_ssl pool_name, alias_str, ssl_cert, private_key
      @logger.debug "add ssl config for alias #{alias_str} from pool #{pool_name}"
      [] # If using AsyncLoadBalancerController, return an array of jobids.
    end

    def remove_ssl pool_name, alias_str
      @logger.debug "remove ssl config for alias #{alias_str} from pool #{pool_name}"
      [] # If using AsyncLoadBalancerController, return an array of jobids.
    end

    def get_job_status id
      @logger.debug "return status of job #{id}"
      "some JSON"
    end

    def authenticate
      @logger.debug "do some authentication stuff"

      @foo = "some temporary token or connection object"
    end

    def initialize logger, cfgfile
      @logger = logger
      @logger.debug "do initialization stuff"
    end

  end

end
