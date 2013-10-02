Dummy::Application.configure do
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
  config.action_controller.perform_caching = false

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

  conf = OpenShift::Config.new(File.join(OpenShift::Config::CONF_DIR, 'broker-dev.conf'))  
  config.ss = {
    :domain_suffix => conf.get("CLOUD_DOMAIN", "example.com"),
    :default_max_gears => (conf.get("DEFAULT_MAX_GEARS", "100")).to_i,
  }

  config.auth = {
    :salt => conf.get("AUTH_SALT", "salt_salt_salt"),
    :mongo_host_port => conf.get("MONGO_HOST_PORT", "localhost:27017"),
    :mongo_user => conf.get("MONGO_USER", "openshift"),
    :mongo_password => conf.get("MONGO_PASSWORD", "mooo"),
    :mongo_db => conf.get("MONGO_TEST_DB", "openshift_broker_test"),
    :privkeyfile => conf.get("AUTH_PRIV_KEY_FILE", "/var/www/openshift/broker/config/server_priv.pem"),
    :privkeypass => conf.get("AUTH_PRIV_KEY_PASS", ""),
    :pubkeyfile => conf.get("AUTH_PUB_KEY_FILE", "/var/www/openshift/broker/config/server_pub.pem"),
    :ssl => conf.get_bool("MONGO_SSL", "false")
  }

 config.user_action_logging = {
    :logging_enabled => false,
    :log_filepath => "/var/log/openshift/user_action.log"
  }
end
