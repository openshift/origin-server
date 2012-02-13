require 'test_helper'

class RestApiTest < ActiveSupport::TestCase

  def setup
    #if @@integrated
      setup_integrated
    #else
    #  setup_mock
    #end
  end

  def setup_integrated
    host = ENV['LIBRA_HOST'] || 'localhost'
    RestApi::Base.site = "https://#{host}/broker/rest"
    RestApi::Base.prefix='/broker/rest/'

    @ts = "#{Time.now.to_i}#{gen_small_uuid[0,6]}"

    @user = RestApi::Authorization.new "test1+#{@ts}@test1.com", @ts

    auth_headers = {'Authorization' => "Basic #{Base64.encode64("#{@user.login}:#{@user.password}").strip}"}

    domain = Domain.new :namespace => "#{@ts}", :as => @user
    assert domain.save
  end

  # TODO fix
  def setup_mock
    require 'active_resource/http_mock'

    @user = RestApi::Authorization.new 'test1', '1234'
    auth_headers = {'Cookie' => "rh_sso=1234", 'Authorization' => 'Basic dGVzdDE6'};

    RestApi::Base.site = 'https://localhost'
    Key.prefix = '/user/'
    User.prefix = '/'
    Domain.prefix = '/'
    Application.prefix = "#{Domain.prefix}domains/:domain_name/"
    ActiveSupport::XmlMini.backend = 'REXML'
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/user/keys.json', {'Accept' => 'application/json'}.merge!(auth_headers), [{:type => :rsa, :name => 'test1', :value => '1234' }].to_json()
      mock.post '/user/keys.json', {'Content-Type' => 'application/json'}.merge!(auth_headers), {:type => :rsa, :name => 'test2', :value => '1234_2' }.to_json()
      mock.delete '/user/keys/test1.json', {'Accept' => 'application/json'}.merge!(auth_headers), {}
      mock.get '/user.json', {'Accept' => 'application/json'}.merge!(auth_headers), { :login => 'test1' }.to_json()
      mock.get '/domains.json', {'Accept' => 'application/json'}.merge!(auth_headers), [{ :namespace => 'adomain' }].to_json()
      mock.get '/domains/adomain/applications.json', {'Accept' => 'application/json'}.merge!(auth_headers), [{ :name => 'app1' }, { :name => 'app2' }].to_json()
    end
  end

  def test_key_get_all
    items = Key.find :all, :as => @user
    assert_equal 0, items.length
  end

  def test_key_first
    assert_equal Key.first(:as => @user), Key.find(:all, :as => @user)[0]
  end

  def test_key_create
    items = Key.find :all, :as => @user

    orig_num_keys = items.length

    key = Key.new :type => 'ssh-rsa', :name => "test#{@ts}", :content => @ts, :as => @user
    assert key.save

    items = Key.find :all, :as => @user
    assert_equal orig_num_keys + 1, items.length
  end

  def test_key_validation
    key = Key.new :type => 'ssh-rsa', :name => 'test2', :as => @user
    assert !key.save
    assert_equal 1, key.errors[:content].length

    key.content = ''
    assert !key.save
    assert_equal 1, key.errors[:content].length

    key.content = 'a'
    assert key.save
    assert key.errors.empty?
  end

  def test_key_delete
    items = Key.find :all, :as => @user

    orig_num_keys = items.length

    key = Key.new :type => 'ssh-rsa', :name => "test#{@ts}", :content => @ts, :as => @user
    assert key.save

    items = Key.find :all, :as => @user
    assert_equal orig_num_keys + 1, items.length

    # Bug #789786, when fixed will handle issue
    assert_raise ActiveResource::ServerError do
      assert items[items.length-1].destroy

      items = Key.find :all, :as => @user
      assert_equal orig_num_keys, items.length
    end
  end

  def test_agnostic_connection
    assert_raise RestApi::MissingAuthorizationError do
      RestApi::Base.connection.is_a? ActiveResource::Connection
    end
    assert RestApi::Base.connection({:as => {}}).is_a? RestApi::UserAwareConnection
  end

  def test_create_cookie
    connection = RestApi::UserAwareConnection.new 'http://localhost', :xml, RestApi::Authorization.new('test1', '1234')
    headers = connection.authorization_header(:post, '/something')
    assert_equal 'rh_sso=1234', headers['Cookie']
  end

  def test_user_get
    user = User.find :one, :as => @user
    assert user
    assert_equal @user.login, user.login
  end

  def test_domain_namespaces
    domain = Domain.new
    assert_nil domain.name, domain.namespace
    domain.name = '1'
    assert_equal '1', domain.name, domain.namespace
    domain.namespace = '2'
    assert_equal '2', domain.name, domain.namespace

    domain = Domain.new :name => 'hello'
    assert_equal 'hello', domain.name, domain.namespace

    domain = Domain.new :namespace => 'hello'
    assert_equal 'hello', domain.name, domain.namespace
  end

  def test_domains_get
    domains = Domain.find :all, :as => @user
    assert_equal 1, domains.length
    assert_equal "#{@ts}", domains[0].namespace
  end

  def test_domains_first
    domain = Domain.first(:as => @user)
    assert_equal "#{@ts}", domain.namespace
  end

  def test_domains_update
    domains = Domain.find :all, :as => @user
    assert_equal 1, domains.length
    assert_equal "#{@ts}", domains[0].namespace

    d = domains[0]
    d.namespace = "#{@ts.reverse}"

    assert d.save

    domains = Domain.find :all, :as => @user
    assert_equal 1, domains.length
    assert_equal "#{@ts.reverse}", domains[0].namespace
  end

  def test_domain_assignment_to_application
    app = Application.new :domain_name => '1'
    assert_equal '1', app.domain_id, app.domain_name

    app = Application.new :domain_id => '1'
    assert_equal '1', app.domain_id, app.domain_name

    domain = Domain.first(:as => @user)

    app = Application.new :as => @user
    assert_nil app.domain_id
    assert_nil app.domain_name

    app.domain_id = 'test'
    assert_equal 'test', app.domain_id, app.domain_name

    app.domain_name = 'test2'
    assert_equal 'test2', app.domain_id, app.domain_name

    app.domain_name = domain.namespace
    assert_equal domain, app.domain

    app = Application.new :as => @user
    app.domain = domain
    assert_equal domain.namespace, app.domain_id, app.domain_name
  end

  def test_domains_applications
    domain = Domain.first(:as => @user)

    app1 = Application.new :name => 'app1', :cartridge => 'php-5.3', :as => @user
    app2 = Application.new :name => 'app2', :cartridge => 'php-5.3', :as => @user

    app1.domain = domain
    app2.domain = domain

    assert app1.save
    assert app2.save

    apps = domain.applications
    assert_equal 2, apps.length
    assert_equal 'app1', apps[0].name
    assert_equal 'app2', apps[1].name
  end
end
