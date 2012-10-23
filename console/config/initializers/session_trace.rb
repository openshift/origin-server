if Rails.version.to_f == 3.0 and Rails.env.development?
  class ActiveSupport::MessageVerifier::InvalidSignature
    def initialize(*arguments)
      Rails.logger.warn "> Unable to verify cookie signature, session cannot be decoded" if caller.find{ |c| c.include? File.join('middleware', 'cookies.rb') }
    end
  end
  class ActionDispatch::Session::CookieStore < ActionDispatch::Session::AbstractStore
    def unpacked_cookie_data(env)
      env["action_dispatch.request.unsigned_session_cookie"] ||= begin
        stale_session_check! do
          request = ActionDispatch::Request.new(env)
          ssn = request.cookie_jar[@key]
          if ssn && ssn.include?('--')
            undecoded = ssn[0,ssn.index('--')] 
            decoded = ActiveSupport::Base64.decode64(undecoded)
            begin
              Rails.logger.warn "> Session: #{Marshal.load(decoded).inspect}"
            rescue StandardError => e
              Rails.logger.warn "> Session unreadable (#{e.class}: #{e}): #{undecoded}"
            end
          else
            Rails.logger.warn "> No session #{ssn}"
          end
          if data = request.cookie_jar.signed[@key]
            data.stringify_keys!
          end
          data || {}
        end
      end
    end
  end
end
