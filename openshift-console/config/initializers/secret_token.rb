# Be sure to restart your server when you modify this file.
require 'console/config_file'

conf = Console::ConfigFile.new(Rails.application.config.configfile)

session_secret = conf[:SESSION_SECRET]
if session_secret.blank?
  Rails.logger.error "\nWARNING: Please configure SESSION_SECRET in #{file}.  " +
                     "Run oo-accept-broker for details."

  # We don't want to prevent an application from starting if this new setting
  # is missing.  In that case we will use the previously hardcoded value.
  OpenshiftConsole::Application.config.secret_token = 'bc09e1f022b83b744a16e72d92dc2bb5b6778e1526617e5bee8e89c13e80edb208335823a456773827f62b3b91392f36c6c264006a49a2ed96baea9c7a599fd0'
else

  # Your secret key for verifying the integrity of signed cookies.
  # If you change this key, all old signed cookies will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  OpenshiftConsole::Application.config.secret_token = Digest::SHA512.hexdigest(session_secret)
end
