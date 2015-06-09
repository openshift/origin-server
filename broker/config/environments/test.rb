Broker::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and enable caching
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

  config.log_level = :debug

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
  config.assets.logger = false


  ############################################
  # OpenShift Configuration Below this point #
  ############################################
  conf = OpenShift::Config.new(File.join(OpenShift::Config::CONF_DIR, 'broker-dev.conf'))
  config.datastore = {
    :host_port => conf.get("MONGO_HOST_PORT", "localhost:27017"),
    :user => conf.get("MONGO_USER", "openshift"),
    :password => conf.get("MONGO_PASSWORD", "mooo"),
    :db => conf.get("MONGO_TEST_DB", "openshift_broker_test"),
    :ssl => conf.get_bool("MONGO_SSL", "false"),
    :write_replicas => conf.get("MONGO_WRITE_REPLICAS", 1).to_i
  }

  config.usage_tracking = {
    :datastore_enabled => conf.get_bool("ENABLE_USAGE_TRACKING_DATASTORE", "true"),
    :audit_log_enabled => conf.get_bool("ENABLE_USAGE_TRACKING_AUDIT_LOG", "true"),
    :audit_log_filepath => conf.get("USAGE_TRACKING_AUDIT_LOG_FILE", "/var/log/openshift/broker/usage.log")
  }

  config.analytics = {
    :enabled => conf.get_bool("ENABLE_ANALYTICS", "false") # global flag for whether any analytics should be enabled
  }

  config.user_action_logging = {
    :logging_enabled => conf.get_bool("ENABLE_USER_ACTION_LOG", "true"),
    :log_filepath => conf.get("USER_ACTION_LOG_FILE", "/var/log/openshift/broker/user_action.log")
  }

  config.maintenance = {
    :enabled => conf.get_bool("ENABLE_MAINTENANCE_MODE", "false"),
    :outage_msg_filepath => conf.get("MAINTENANCE_NOTIFICATION_FILE", "/etc/openshift/outage_notification.txt")
  }

  config.openshift = {
    :domain_suffix => conf.get("CLOUD_DOMAIN", "example.com"),
    :allow_alias_in_domain => conf.get_bool("ALLOW_ALIAS_IN_DOMAIN", "false"),
    :prevent_alias_collision => conf.get_bool("PREVENT_ALIAS_COLLISION", "true"), # almost always want this. https://trello.com/c/ASq1CXyv
    :default_max_domains => (conf.get("DEFAULT_MAX_DOMAINS", "10")).to_i,
    :default_max_gears => (conf.get("DEFAULT_MAX_GEARS", "100")).to_i,
    :default_gear_size => conf.get("DEFAULT_GEAR_SIZE", "small"),
    :gear_sizes => conf.get("VALID_GEAR_SIZES", "small").split(","),
    :hidden_gear_sizes => [],
    :cartridge_gear_sizes => OpenShift::Controller::Configuration.parse_tokens_hash("mock-no-small|medium,large,c9"),
    :default_gear_capabilities => conf.get("DEFAULT_GEAR_CAPABILITIES", "small").split(","),
    :default_allow_ha => conf.get_bool('DEFAULT_ALLOW_HA', "false"),
    :scopes => ['Scope::Session', 'Scope::Read', 'Scope::Domain', 'Scope::Application', 'Scope::Userinfo', 'Scope::Sso', 'Scope::OauthAccessToken'],
    :default_scope => 'userinfo',
    :scope_expirations => OpenShift::Controller::Configuration.parse_expiration("session=1.days|2.days, oauthaccesstoken=10.minutes|10.minutes", 1.month),
    :download_cartridges_enabled => conf.get_bool("DOWNLOAD_CARTRIDGES_ENABLED", "true"),
    :ssl_endpoint => conf.get("SSL_ENDPOINT", "allow"),
    :max_members_per_resource => conf.get('MAX_MEMBERS_PER_RESOURCE', '100').to_i,
    :max_teams_per_resource => conf.get('MAX_TEAMS_PER_RESOURCE', '5').to_i,
    :allow_ha_applications => conf.get_bool('ALLOW_HA_APPLICATIONS', "false"),
    :manage_ha_dns => conf.get_bool('MANAGE_HA_DNS', "false"),
    :default_ha_multiplier => (conf.get("DEFAULT_HA_MULTIPLIER", "0")).to_i,
    :router_hostname => conf.get('ROUTER_HOSTNAME', "www.example.com"),
    :ha_dns_prefix => conf.get('HA_DNS_PREFIX', "ha-"),
    :ha_dns_suffix => conf.get('HA_DNS_SUFFIX', ""),
    :valid_ssh_key_types => OpenShift::Controller::Configuration.parse_list(conf.get('VALID_SSH_KEY_TYPES', nil)),
    :minimum_ssh_key_size => OpenShift::Controller::Configuration.parse_tokens_hash(conf.get('MINIMUM_SSH_KEY_SIZE', nil)),
    :allow_obsolete_cartridges => conf.get_bool('ALLOW_OBSOLETE_CARTRIDGES', "false"),
    :allow_multiple_haproxy_on_node => conf.get_bool('ALLOW_MULTIPLE_HAPROXY_ON_NODE', "true"),
    :syslog_enabled => conf.get_bool('SYSLOG_ENABLED', 'false'),
    :app_template_for => OpenShift::Controller::Configuration.parse_url_hash(conf.get('DEFAULT_APP_TEMPLATES', nil)),
    :default_max_teams => (conf.get("DEFAULT_MAX_TEAMS", "100")).to_i,
    :default_view_global_teams => conf.get_bool('DEFAULT_VIEW_GLOBAL_TEAMS', 'true'),
    :default_private_ssl_certificates => conf.get_bool('DEFAULT_ALLOW_PRIVATE_SSL_CERTIFICATES', 'false'),
    :node_platforms => OpenShift::Controller::Configuration.parse_list(conf.get('NODE_PLATFORMS', 'linux')).map { |platform| platform.downcase },
    :default_max_untracked_addtl_storage_per_gear => (conf.get("DEFAULT_MAX_UNTRACKED_ADDTL_STORAGE_PER_GEAR", "0")).to_i,
    :default_max_tracked_addtl_storage_per_gear => (conf.get("DEFAULT_MAX_TRACKED_ADDTL_STORAGE_PER_GEAR", "0")).to_i,
    :default_region_name => conf.get("DEFAULT_REGION_NAME", ""),
    :allow_region_selection => conf.get_bool("ALLOW_REGION_SELECTION", 'true'),
    :normalize_username_method => conf.get("NORMALIZE_USERNAME_METHOD", "noop"),
    :use_predictable_gear_uuids => conf.get_bool("USE_PREDICTABLE_GEAR_UUIDS", false),
    :limit_app_name_chars => conf.get("LIMIT_APP_NAME_CHARS", -1).to_i,
    :app_advertise_https => conf.get_bool("APP_ADVERTISE_HTTPS", false),
  }

  config.auth = {
    :salt => conf.get("AUTH_SALT", ""),
    :privkeyfile => conf.get("AUTH_PRIV_KEY_FILE", "/var/www/openshift/broker/config/server_priv.pem"),
    :privkeypass => conf.get("AUTH_PRIV_KEY_PASS", ""),
    :pubkeyfile  => conf.get("AUTH_PUB_KEY_FILE", "/var/www/openshift/broker/config/server_pub.pem"),
    :rsync_keyfile => conf.get("AUTH_RSYNC_KEY_FILE", "/etc/openshift/rsync_id_rsa")
  }

  config.downloaded_cartridges = {
    :max_downloaded_carts_per_app => conf.get("MAX_DOWNLOADED_CARTS_PER_APP", "5").to_i,
    :max_download_redirects => conf.get("MAX_DOWNLOAD_REDIRECTS", "2").to_i,
    :max_cart_size => conf.get("MAX_CART_SIZE", "20480").to_i,
    :max_download_time => conf.get("MAX_DOWNLOAD_TIME", "10").to_i
  }

  config.logger = OpenShift::Syslog.logger_for('openshift-broker', 'app') if config.openshift[:syslog_enabled]

end
