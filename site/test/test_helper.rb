ENV["RAILS_ENV"] = "test"
$:.unshift(File.dirname(__FILE__) + '/../../server-common')
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha'
require 'openshift'
require 'streamline'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  #fixtures :all

  def expects_integrated
    flunk 'Test requires integrated Streamline authentication' unless Rails.configuration.integrated
  end

  def gen_small_uuid()
    %x[/usr/bin/uuidgen].gsub('-', '').strip
  end

  @@name = 0
  def unique_name_format
    'name%i'
  end
  def unique_name(format=nil)
    (format || unique_name_format) % self.class.next
  end
  def self.next
    @@name += 1
  end

  @@once = []
  def once(symbol, &block)
    unless @@once.include? symbol
      @@once << symbol
      exit_block = yield block
      at_exit do
        exit_block.call
      end
    end
  end

  def setup_api
    host = ENV['LIBRA_HOST'] || 'localhost'
    RestApi::Base.site = "https://#{host}/broker/rest"
    RestApi::Base.prefix='/broker/rest/'
  end
  def setup_user(unique=false)
    @user = WebUser.new :email_address=>"app_test1#{unique ? uuid : ''}@test1.com", :rhlogin=>"app_test1#{unique ? uuid : ''}@test1.com"

    session[:login] = @user.login
    session[:ticket] = '123'
    @request.cookies['rh_sso'] = '123'
    @request.env['HTTPS'] = 'on'
  end
  def uuid
    @ts ||= "#{Time.now.to_i}#{gen_small_uuid[0,6]}"
  end

  def setup_domain
    @domain = Domain.new :name => "#{uuid}", :as => @user
    unless @domain.save
      puts @domain.errors.inspect
      fail 'Unable to create the initial domain, test cannot be run'
    end
    @domain
  end

  #
  # Create and authenticate a user that is unique per test case
  #
  def with_unique_user
    setup_api
    uuid
    setup_user(true)
  end

  #
  # Create and authenticate a user that is unique per test case and
  # create an initial domain for that user.
  #
  def with_unique_domain
    with_unique_user
    setup_domain
  end

  #
  # Create a domain and user that are shared by all tests in the test suite, 
  # and is only destroyed at the very end of the suite.  If you do not clean
  # up after creating applications you will hit the application limit for
  # this user.
  #
  def with_domain
    setup_api
    setup_user
    once :domain do
      domain = Domain.first :as => @user
      domain.destroy_recursive if domain
      @@domain = setup_domain
      lambda do
        begin
          @@domain.destroy_recursive
        rescue ActiveResource::ResourceNotFound
        end
      end
    end
    @domain = @@domain
  end
end

