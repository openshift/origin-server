ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

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
      records = Libra::Server.get_dns_txt(namespace)
      user = Libra::User.find(login)

      unless user or !records.empty? or reserved_usernames.index(login)
        result[:login] = login
        result[:namespace] = namespace
        break
      end
    end

    return result
  end
end
