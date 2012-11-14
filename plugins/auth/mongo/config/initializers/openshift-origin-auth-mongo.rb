require 'openshift-origin-common'

Broker::Application.configure do
  conf_file = File.join(OpenShift::Config::PLUGINS_DIR, File.basename(__FILE__, '.rb') + '.conf')
  if Rails.env.development?
    dev_conf_file = File.join(OpenShift::Config::PLUGINS_DIR, File.basename(__FILE__, '.rb') + '-dev.conf')
    if File.exist? dev_conf_file
      conf_file = dev_conf_file
    else
      Rails.logger.info "Development configuration for #{File.basename(__FILE__, '.rb')} not found. Using production configuration."
    end
  end
  conf = OpenShift::Config.new(conf_file)

  # Grab this now because we need it for the MONGO_HOST_PORT parsing.
  replica_sets = conf.get_bool("MONGO_REPLICA_SETS", "false")
  hp = conf.get("MONGO_HOST_PORT", "localhost:27017")

  # Depending on the value of the MONGO_REPLICA_SETS setting, MONGO_HOST_PORT
  # must follow one of two formats, as described below.

  if !hp
    raise "Broker is missing Mongo configuration."
  elif replica_sets
    # The string should be of the following form:
    #
    #   host-1:port-1 host-2:port-2 ...
    #
    # We need to parse into an array of arrays:
    #
    #   [[<host-1>, <port-1>], [<host-2>, <port-2>], ...]
    #
    # where each host is a string and each port is an integer.

    host_port = hp.split.map do |x|
      (h,p) = x.split(":")
      [h, p.to_i]
    end
  else

    # The string should be of the following form:
    #
    #   host:port
    #
    # We need to parse into an array:
    #
    #   [host,port]
    #
    # where host is a string and port is an integer.

    (h,p) = hp.split(":")
    host_port = [h, p.to_i]
  end

  config.auth[:mongo_replica_sets] = replica_sets
  config.auth[:mongo_host_port]    = host_port
  config.auth[:mongo_user] = conf.get("MONGO_USER", "openshift")
  config.auth[:mongo_password] = conf.get("MONGO_PASSWORD", "mooo")
  config.auth[:mongo_db] = conf.get("MONGO_DB", "openshift_broker_dev")
  config.auth[:mongo_collection] = conf.get("MONGO_COLLECTION", "auth_user")
end
