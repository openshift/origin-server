require 'openshift-origin-common/config'

Broker::Application.configure do
  conf = OpenShift::Config.new(File.join(OpenShift::Config::PLUGINS_DIR, File.basename(__FILE__, '.rb') + '.conf'))
  defaults = OpenShift::Config.new(File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb') + '-defaults.conf'))

  # Grab this now because we need it for the MONGO_HOST_PORT parsing.
  replica_sets = conf.get_bool("MONGO_REPLICA_SETS") || defaults.get_bool("MONGO_REPLICA_SETS")

  hp = conf.get("MONGO_HOST_PORT") || defaults.get("MONGO_HOST_PORT")

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

  config.auth = {
    :salt => conf.get("AUTH_SALT") || defaults.get("AUTH_SALT"),
    :privkeyfile => conf.get("AUTH_PRIVKEYFILE") || defaults.get("AUTH_PRIVKEYFILE"),
    :privkeypass => conf.get("AUTH_PRIVKEYPASS") || defaults.get("AUTH_PRIVKEYPASS"),
    :pubkeyfile  => conf.get("AUTH_PUBKEYFILE") || defaults.get("AUTH_PUBKEYFILE"),

    :mongo_replica_sets => replica_sets,
    :mongo_host_port => host_port,

    :mongo_user => conf.get("MONGO_USER") || defaults.get("MONGO_USER"),
    :mongo_password => conf.get("MONGO_PASSWORD") || defaults.get("MONGO_PASSWORD"),
    :mongo_db => conf.get("MONGO_DB") || defaults.get("MONGO_DB"),
    :mongo_collection => conf.get("MONGO_COLLECTION") || defaults.get("MONGO_COLLECTION")
  }
end
