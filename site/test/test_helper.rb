ENV["RAILS_ENV"] = "test"
$:.unshift(File.dirname(__FILE__) + '/../../server-common')
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha'
require 'openshift'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  #fixtures :all

  #
  # Obtain a unique username from S3.
  #
  #   reserved_usernames = A list of reserved names that may
  #     not be in the global store
  #
  def get_unique_username(reserved_usernames=[])
    result={}

    loop do
      # Generate a random username
      chars = ("1".."9").to_a
      namespace = "unit" + Array.new(8, '').collect{chars[rand(chars.size)]}.join
      login = "libra-test+#{namespace}@redhat.com"
      has_txt = Libra::Server.has_dns_txt?(namespace)
      user = Libra::User.find(login)

      unless user or has_txt or reserved_usernames.index(login)
        result[:login] = login
        result[:namespace] = namespace
        break
      end
    end

    return result
  end
  
  def setup_session(role='')
    session[:login] = 'tester'
    session[:user] = WebUser.new
    session[:ticket] = '123'
    @request.cookies['rh_sso'] = '123'
    @request.env['HTTPS'] = 'on'
    session[:user].roles.push(role) unless role.empty?
  end
end

