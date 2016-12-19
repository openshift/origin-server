module OpenShift

  class LBModelException < StandardError; end

  class LBModelExceptionCollector
    def initialize
      @exceptions = []
    end

    def try
      yield
    rescue LBModelException => e
      @exceptions << e
    end

    def to_s
      "got #{@exceptions.length} LBModelException exceptions: " +
        @exceptions.map {|e| e.message}.join('; ')
    end

    def done
      raise LBModelException.new self.to_s unless @exceptions.empty?
    end
  end

  # == Abstract routing model class
  #
  # Presents direct access to a load balancer.  This is an abstract class.
  #
  class LoadBalancerModel

    def get_pool_names
    end

    # create_pool :: String, String -> undefined
    # Note: At least one of create_pool and create_pools must be implemented.
    def create_pool pool_name, monitor_name
    end

    # create_pools :: [String], [String] -> undefined
    # Note: At least one of create_pool and create_pools must be implemented.
    def create_pools pool_names, monitor_names
      pool_names.zip(monitor_names).map {|pool_name, monitor_name| create_pool pool_name, monitor_name}.flatten 1
    end

    # delete_pool :: String -> undefined
    # Note: At least one of delete_pool and delete_pools must be implemented.
    def delete_pool pool_name
    end

    # delete_pools :: [String] -> undefined
    # Note: At least one of delete_pool and delete_pools must be implemented.
    def delete_pools pool_names
      pool_names.map {|pool_name| delete_pool pool_name}.flatten 1
    end

    # get_monitor_names :: [String]
    def get_monitor_names
      []
    end

    # create_monitor :: String, String, String, String, String, String -> undefined
    def create_monitor monitor_name, path, up_code, type, interval, timeout
    end

    # delete_monitor :: String, String -> undefined
    def delete_monitor monitor_name, type
    end

    # add_pool_monitor :: String, String -> undefined
    def add_pool_monitor pool_name, monitor_name
    end

    # delete_pool_monitor :: String, String -> undefined
    def delete_pool_monitor pool_name, monitor_name
    end

    # get_pool_monitors :: String -> [String]
    def get_pool_monitors pool_name
    end

    def get_pool_certificates pool_name
      @logger.debug "get pool certificates #{pool_name}"
      [] # Return an array of String representing certificates.
    end

    # get_pool_members :: String -> [String]
    def get_pool_members pool_name
      []
    end

    # get_active_pool_members :: String -> [String]
    def get_active_pool_members pool_name
      []
    end

    # add_pool_member :: String, String, Integer -> undefined
    # Note: At least one of add_pool_member and add_pool_members must be
    # implemented.
    def add_pool_member pool_name, address, port
      add_pool_members [pool_name], [[[address, port]]]
    end

    # add_pool_members :: [String], [[[String,Integer]]] -> undefined
    # Each member comprises an IP address in dotted-quad representation and a port.
    # Note: At least one of add_pool_member and add_pool_members must be
    # implemented.
    def add_pool_members pool_names, member_lists
      (pool_names.zip member_lists).map do |pool,members|
        members.map {|address,port| add_pool_member pool, address, port}
      end.flatten 2
    end

    # delete_pool_member :: String, String, Integer -> undefined
    # Note: At least one of delete_pool_member and delete_pool_members must be
    # implemented.
    def delete_pool_member pool_name, address, port
      delete_pool_members [pool_name], [[[address, port]]]
    end

    # delete_pool_members :: [String], [[[String,Integer]]] -> undefined
    # Note: At least one of delete_pool_member and delete_pool_members must be
    # implemented.
    def delete_pool_members pool_names, member_lists
      (pool_names.zip member_lists).map do |pool,members|
        members.map {|address,port| delete_pool_member pool, address, port}
      end.flatten 2
    end

    # get_pool_aliases :: String -> [String]
    def get_pool_aliases pool_name
      []
    end

    # add_pool_alias :: String, String -> undefined
    def add_pool_alias pool_name, alias_str
    end

    # delete_pool_alias :: String, String -> undefined
    def delete_pool_alias pool_name, alias_str
    end

    # add_ssl :: String, String, String, String
    def add_ssl pool_name, alias_str, ssl_cert, private_key
    end

    # remove_ssl pool_name, alias_str :: String, String
    def remove_ssl pool_name, alias_str
    end

    # get_job_status :: String -> Object
    # This is only needed if the model is being used with
    # AsyncLoadBalancerController.
    def get_job_status id
    end

    def authenticate
    end

    def initialize cfgfile=nil
      @cfgfile = cfgfile
    end

  end

end
