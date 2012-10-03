# Be sure to restart your server when you modify this file.

Broker::Application.config.session_store :cookie_store, :key => '_openshift_origin_broker_session',
                                                             :secure => true, # Only send cookie over SSL when in production mode
                                                             :http_only => true, # Don't allow Javascript to access the cookie (mitigates cookie-based XSS exploits)
                                                             :expire_after => nil


# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Broker::Application.config.session_store :active_record_store
