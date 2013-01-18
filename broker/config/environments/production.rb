Broker::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  ############################################
  # OpenShift Configuration Below this point #
  ############################################

  conf = OpenShift::Config.new(File.join(OpenShift::Config::CONF_DIR, 'broker.conf'))
  replica_sets = conf.get_bool("MONGO_REPLICA_SETS", "true")
  hp = conf.get("MONGO_HOST_PORT", "localhost:27017")
  if !hp
    raise "Broker is missing Mongo configuration."
  elsif replica_sets
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

  config.datastore = {
    :replica_set => replica_sets,
    # Replica set example: [[<host-1>, <port-1>], [<host-2>, <port-2>], ...]
    :host_port => host_port,

    :user => conf.get("MONGO_USER", "openshift"),
    :password => conf.get("MONGO_PASSWORD", "mooo"),
    :db => conf.get("MONGO_DB", "openshift_broker_dev"),
    :collections => {:user => "user",
                     :district => "district",
                     :application_template => "template"},
    :ssl => conf.get_bool("MONGO_SSL", "false")
  }

  config.usage_tracking = {
    :datastore_enabled => conf.get_bool("ENABLE_USAGE_TRACKING_DATASTORE", "false"),
    :syslog_enabled => conf.get_bool("ENABLE_USAGE_TRACKING_SYSLOG", "false")
  }

  config.analytics = {
    :enabled => conf.get_bool("ENABLE_ANALYTICS", "false"), # global flag for whether any analytics should be enabled
  }

  config.user_action_logging = {
    :logging_enabled => conf.get_bool("ENABLE_USER_ACTION_LOG", "true"),
    :log_filepath => conf.get("USER_ACTION_LOG_FILE", "/var/log/openshift/user_action.log")
  }

  config.openshift = {
    :domain_suffix => conf.get("CLOUD_DOMAIN", "example.com"),
    :default_max_gears => (conf.get("DEFAULT_MAX_GEARS", "100")).to_i,
    :default_gear_size => conf.get("DEFAULT_GEAR_SIZE", "small"),
    :gear_sizes => conf.get("VALID_GEAR_SIZES", "small,medium").split(","),
    :default_gear_capabilities => conf.get("DEFAULT_GEAR_CAPABILITIES", "small").split(","),
    :community_quickstarts_url => conf.get("COMMUNITY_QUICKSTARTS_URL"),
  }

  config.auth = {
    :salt => conf.get("AUTH_SALT", ""),
    :privkeyfile => conf.get("AUTH_PRIVKEYFILE", "/var/www/openshift/broker/config/server_priv.pem"),
    :privkeypass => conf.get("AUTH_PRIVKEYPASS", ""),
    :pubkeyfile  => conf.get("AUTH_PUBKEYFILE", "/var/www/openshift/broker/config/server_pub.pem"),
    :rsync_keyfile => conf.get("AUTH_RSYNC_KEY_FILE", "/etc/openshift/rsync_id_rsa")
  }
end
