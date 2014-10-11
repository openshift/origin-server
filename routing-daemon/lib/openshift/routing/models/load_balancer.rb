module OpenShift

  class LBModelException < StandardError; end

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

    def get_route_names
      []
    end

    def get_active_route_names
      []
    end

    # create_route :: String, String, String -> undefined
    # Note: At least one of create_route and create_routes must be implemented.
    def create_route pool_name, route_name, path
      create_routes [pool_name], [[route_name, path]]
    end

    # create_routes :: [String], [[String,String]] -> undefined
    # Each route comprises a name and a path.
    # Note: At least one of create_route and create_routes must be implemented.
    def create_routes pool_names, routes
      (pool_names.zip routes).map {|pool,(route,path)| create_route pool, route, path}.flatten 1
    end

    # attach_route :: String, String -> undefined
    # Note: At least one of attach_route and attach_routes must be implemented.
    def attach_route route_name, virtual_server_name
      attach_routes [route_name], [virtual_server_name]
    end

    # attach_routes :: [String], [String] -> undefined
    # Note: At least one of attach_route and attach_routes must be implemented.
    def attach_routes route_names, virtual_server_names
      (route_names.zip virtual_server_names).map {|route_name, virtual_server_name| attach_route route_name, virtual_server_name}.flatten 1
    end

    def detach_route route_name, virtual_server_name
      detach_routes [route_name], [virtual_server_name]
    end

    def detach_routes route_names, virtual_server_names
      (route_names.zip virtual_server_names).map {|route_name, virtual_server_name| detach_route route_name, virtual_server_name}.flatten 1
    end

    # delete_route :: String, String -> undefined
    # Note: At least one of delete_route and delete_routes must be implemented.
    def delete_route pool_name, route_name
      delete_routes [pool_name], [route_name]
    end

    # delete_routes :: [String], [String] -> undefined
    # Note: At least one of delete_route and delete_routes must be implemented.
    def delete_routes pool_names, route_names
      (pool_names.zip route_names).map {|pool,route| delete_route pool, route}.flatten 1
    end

    # get_monitor_names :: [String]
    def get_monitor_names
      []
    end

    # create_monitor :: String, String, String, String, String, String -> undefined
    def create_monitor monitor_name, path, up_code, type, interval, timeout
    end

    # delete_monitor :: String -> undefined
    def delete_monitor monitor_name
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
