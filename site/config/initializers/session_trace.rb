if Rails.env.development?
  class ActiveSupport::MessageVerifier::InvalidSignature
    def initialize(*arguments)
      Rails.logger.warn "> Unable to verify cookie signature, session cannot be decoded" if caller.find{ |c| c.include? File.join('middleware', 'cookies.rb') }
    end
  end
end
