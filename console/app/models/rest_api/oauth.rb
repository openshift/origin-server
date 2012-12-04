require 'uri'
require 'openssl'
require 'base64'

module RestApi
  module OAuth
    extend ActiveSupport::Concern

    SIGNATURE_METHOD = "HMAC-SHA1"
    OAUTH_VERSION = "1.0"
    CONTENT_TYPE = 'application/x-www-form-urlencoded'
    METHOD = 'GET'

    attr_reader :oauth_consumer_key, :oauth_consumer_secret, :oauth_token, :oauth_token_secret, :oauth_nonce

    def oauth(consumer_key, consumer_secret, token, token_secret)
      @oauth_consumer_key, @oauth_consumer_secret, @oauth_token, @oauth_token_secret = consumer_key, consumer_secret, token, token_secret
      @oauth_nonce = create_oauth_nonce
      headers['Content-Type'] = CONTENT_TYPE
      headers['Authorization'] = oauth_authorization_header
    end

    private
      def oauth_parameters
        @oauth_parameters ||= {
          'oauth_consumer_key' => @oauth_consumer_key,
          'oauth_nonce' => @oauth_nonce,
          'oauth_signature_method' => SIGNATURE_METHOD,
          'oauth_timestamp' => timestamp,
          'oauth_token' => @oauth_token,
          'oauth_version' => OAUTH_VERSION
        }
      end

      def oauth_authorization_header
        'OAuth ' + 
        oauth_parameters.sort.map{|k,v| "#{percent_encode(k)}=\"#{percent_encode(v)}\""}.join(', ') + 
        ', ' + 
        "oauth_signature=\"#{percent_encode(oauth_signature)}\""
      end

      def create_oauth_nonce
        Array.new(5) { rand(256) }.pack('C*').unpack('H*').first
      end

      def oauth_signature
        signing_key = percent_encode(oauth_consumer_secret) + '&' + percent_encode(oauth_token_secret)
        signature_base_string = [
          METHOD, 
          percent_encode(RETWEETS_ENDPOINT_URL), 
          percent_encode(oauth_parameters.sort.map{|k,v| "#{percent_encode(k)}=#{percent_encode(v)}"}.join('&'))
        ].join('&')
        digest = OpenSSL::Digest::Digest.new('sha1')
        hmac = OpenSSL::HMAC.digest(digest, signing_key, signature_base_string)
        Base64.encode64(hmac).chomp.gsub(/\n/, '')
      end

      def timestamp
        Time.now.to_i.to_s
      end

      def percent_encode(string)
        return URI.escape(string, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")).gsub('*', '%2A')
      end
    end

  end
end
