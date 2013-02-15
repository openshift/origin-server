# Be sure to restart your server when you modify this file.

OpenshiftConsole::Application.config.session_store :cookie_store, :key => '_openshift_origin_session',
                                                             :secure => true, # Only send cookie over SSL when in production mode
                                                             :http_only => true, # Don't allow Javascript to access the cookie (mitigates cookie-based XSS exploits)
                                                             :expire_after => nil
