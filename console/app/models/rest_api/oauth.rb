require 'uri'
require 'cgi'
require 'openssl'
require 'base64'
require 'securerandom'

module RestApi
  module Oauth
    extend ActiveSupport::Concern

    module ClassMethods

      SIGNATURE_METHOD = "HMAC-SHA1"
      OAUTH_VERSION = "1.0"
      CONTENT_TYPE = 'application/x-www-form-urlencoded'
      METHOD = 'GET'
      ACCEPT = 'application/json'

      attr_reader :oauth_endpoint_uri, :oauth_consumer_key, :oauth_consumer_secret, :oauth_token, :oauth_token_secret, :oauth_nonce

      def oauth(endpoint_url, consumer_key, consumer_secret, token, token_secret)
        @oauth_endpoint_uri = URI(endpoint_url)
        @oauth_consumer_key, @oauth_consumer_secret, @oauth_token, @oauth_token_secret = consumer_key, consumer_secret, token, token_secret
        @oauth_nonce = generate_oauth_nonce
        @timestamp = timestamp
        headers['Content-Type'] = CONTENT_TYPE
        headers['Accept'] = ACCEPT
        headers['Authorization'] = oauth_authorization_header
        headers
      end

      private
        def oauth_parameters
          {
            'oauth_consumer_key' => @oauth_consumer_key,
            'oauth_nonce' => @oauth_nonce,
            'oauth_signature_method' => SIGNATURE_METHOD,
            'oauth_timestamp' => @timestamp,
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

        def oauth_signature
          signing_key = percent_encode(@oauth_consumer_secret) + '&' + percent_encode(@oauth_token_secret)
          query_string = CGI::parse(@oauth_endpoint_uri.query) rescue {}
          signature_base_string = [
            METHOD, 
            percent_encode(@oauth_endpoint_uri.scheme + "://" + @oauth_endpoint_uri.host + @oauth_endpoint_uri.path), 
            percent_encode(oauth_parameters.merge(query_string).sort.map{|k,v| "#{percent_encode(k)}=#{percent_encode(v.kind_of?(Array) ? v.first : v)}"}.join('&'))
          ].join('&')
          digest = OpenSSL::Digest::Digest.new('sha1')
          hmac = OpenSSL::HMAC.digest(digest, signing_key, signature_base_string)
          Base64.encode64(hmac).chomp.gsub(/\n/, '')
        end

        def generate_oauth_nonce
          SecureRandom.hex
        end

        def timestamp
          Time.now.to_i.to_s
        end

        def percent_encode(string)
          CGI.escape string
        end
    end
  end
end