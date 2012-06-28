# Create random key based on the OPENSHIFT_SECRET_TOKEN

require 'logger'
require 'digest/sha2'

# Public: Generate secure secret variable
#
# name    - the name of the variable to generate
# default - the default value
#
# Returns a hash value to use as a secure variable
def initialize_secret(name,default)
  # Only generate token based if we're running on OPENSHIFT
  if secret = get_env_secret
    # Create seed for random function from secret and name
    seed = [secret,name.to_s].join('-')
    # Generate hash from seed
    hash = Digest::SHA512.hexdigest(seed)
    # Set token, ensuring it is the same length as the default
    hash[0,default.length]
  else
    openshift_log "Unable to get OPENSHIFT_SECRET_TOKEN, using default"
    default
  end
end

private

# Private: Log messages
#
# msg - The message to log
# dev - The severity (defaults to warn)
def openshift_log(msg,sev = Logger::WARN)
  logger = defined?(Rails) ? Rails.logger : Logger.new(STDERR)
  logger.add(sev){msg}
end

# Private: Return a secret token to use
#
# Returns a secret token or nil (if not running on OpenShift)
def get_env_secret
  ENV['OPENSHIFT_SECRET_TOKEN'] || generate_secret_token
end

# Private: Generates a pseudo-secure secret token
#
# Returns a hashed secret token or nil (if not running on OpenShift)
def generate_secret_token
  openshift_log("No secret token environment variable set", Logger::DEBUG)
  (name,uuid) = ENV.values_at('OPENSHIFT_APP_NAME','OPENSHIFT_APP_UUID')
  if name && uuid
    openshift_log "Running on Openshift, creating OPENSHIFT_SECRET_TOKEN"
    Digest::SHA256.hexdigest([name,uuid].join('-'))
  else
    nil
  end
end
