# Be sure to restart your server when you modify this file.

conf_file = if Rails.env.development?
  File.join(OpenShift::Config::CONF_DIR, 'broker-dev.conf')
else
  File.join(OpenShift::Config::CONF_DIR, 'broker.conf')
end
conf = OpenShift::Config.new(conf_file)

auth_salt = conf.get("AUTH_SALT")
if auth_salt.blank?
  raise "\nYou must set AUTH_SALT in #{conf_file}."
elsif auth_salt == "ClWqe5zKtEW4CJEMyjzQ"
  Rails.logger.error "\nWARNING: You are using the default value for for AUTH_SALT in #{conf_file}!"
end

rails_secret = conf.get("SESSION_SECRET")
if rails_secret.blank?
  Rails.logger.error "\nWARNING: Please configure SESSION_SECRET in #{conf_file}.  " +
                     "Run oo-accept-broker for details."

  # We don't want to prevent an application from starting if this new setting
  # is missing.  In that case we will use the AUTH_SALT since we know that it
  # exists and is the same across all Brokers.
  rails_secret = auth_salt
end

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Broker::Application.config.secret_token = Digest::SHA512.hexdigest(rails_secret)
