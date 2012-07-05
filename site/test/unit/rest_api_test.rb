require File.expand_path('../../test_helper', __FILE__)

require 'active_resource/persistent_http_mock'

#
# Mock tests only - should verify functionality of ActiveResource extensions
# and simple server/client interactions via HttpMock
#
class RestApiTest < ActiveSupport::TestCase
  setup { Rails.cache.clear }

  def setup
    RestApi::Base.site = "https://mock.test/broker/rest"

    @ts = "#{Time.now.to_i}#{gen_small_uuid[0,6]}"

    @user = RestApi::Authorization.new 'test1', '1234'
    @auth_headers = {'Cookie' => "rh_sso=1234", 'Authorization' => 'Basic dGVzdDE6'};

    #RestApi::Base.site = 'https://'
    #Key.prefix = '/user/'
    #User.prefix = '/'
    #Domain.prefix = '/'
    #Application.prefix = "#{Domain.prefix}domains/:domain_name/"
    ActiveSupport::XmlMini.backend = 'REXML'
  end

  def mock
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/user/keys.json', {'Accept' => 'application/json'}.merge!(@auth_headers), [{:type => :rsa, :name => 'test1', :value => '1234' }].to_json()
      mock.post '/broker/user/keys.json', {'Content-Type' => 'application/json'}.merge!(@auth_headers), {:type => :rsa, :name => 'test2', :value => '1234_2' }.to_json()
      mock.delete '/user/keys/test1.json', {'Accept' => 'application/json'}.merge!(@auth_headers), {}
      mock.get '/user.json', {'Accept' => 'application/json'}.merge!(@auth_headers), { :login => 'test1' }.to_json()
      mock.get '/domains.json', {'Accept' => 'application/json'}.merge!(@auth_headers), [{ :name => 'adomain' }].to_json()
      mock.get '/domains/adomain/applications.json', {'Accept' => 'application/json'}.merge!(@auth_headers), [{ :name => 'app1' }, { :name => 'app2' }].to_json()
    end
  end

  def json_header(is_post=false)
    {(is_post ? 'Content-Type' : 'Accept') => 'application/json'}.merge!(@auth_headers)
  end

  def test_base_connection
    base = RestApi::Base.new :as => @user
    connection = base.send('connection')
    assert connection
    assert_equal connection, base.send('connection') #second request preserves connection
    assert_not_equal connection, base.send('connection', true) #forced refresh creates new connection
  end

  def test_agnostic_connection
    assert_raise RestApi::MissingAuthorizationError do
      RestApi::Base.connection
    end
    assert RestApi::Base.connection({:as => {}}).is_a? RestApi::UserAwareConnection
  end

  def test_translate_api_error
    (errors = mock).expects(:add).once.with(:base, 'test')
    RestApi::Base.translate_api_error(errors, nil, nil, 'test')
    (errors = mock).expects(:add).once.with(:test, 'test')
    RestApi::Base.translate_api_error(errors, nil, :test, 'test')
    (errors = mock).expects(:add).once.with(:test, 'test')
    RestApi::Base.translate_api_error(errors, nil, 'test', 'test')
    (errors = mock).expects(:add).once.with(:test, 'Type is required and cannot be blank.')
    RestApi::Base.translate_api_error(errors, '116', 'test', 'test')
    (errors = mock).expects(:add).once.with(:base, 'Type is required and cannot be blank.')
    RestApi::Base.translate_api_error(errors, '116', nil, nil)
  end

  def test_has_exit_code
    a = RestApi::Base.new
    a.errors.instance_variable_set(:@codes, {:a => ['1']})
    assert a.has_exit_code? 1
    assert a.has_exit_code? 1, :on => 'a'
    assert a.has_exit_code? 1, :on => :a
    assert !a.has_exit_code?(1, :on => :b)

    a.errors.instance_variable_set(:@codes, {:a => ['1','2']})
    assert a.has_exit_code? 1
    assert a.has_exit_code? 2
    assert a.has_exit_code? 1, :on => 'a'
    assert a.has_exit_code? 1, :on => :a
    assert !a.has_exit_code?(1, :on => :b)
  end

  def test_has_exit_code_real
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post '/broker/rest/domains.json', json_header(true), {:messages => [{:field => 'foo', :exit_code => 1, 'text' => 'bar'}], :data => nil}.to_json, 500
    end

    d = Domain.new(:id => 'a', :as => @user)
    assert !d.save
    assert d.has_exit_code?(1), d.attributes.pretty_inspect
    assert d.has_exit_code? 1, :on => 'foo'
    assert d.has_exit_code? 1, :on => :foo
    assert !d.has_exit_code?(1, :on => :foobar)
  end

  def response(contents)
    object = mock
    body = mock
    body.stubs(:body => contents)
    object.stubs(:response => body)
    object
  end

  def test_load_remote_errors
    assert_raise RestApi::BadServerResponseError do RestApi::Base.new.load_remote_errors(stub(:response => {})); end
    assert_raise RestApi::BadServerResponseError do RestApi::Base.new.load_remote_errors(stub(:response => stub(:body => nil))); end
    assert_raise RestApi::BadServerResponseError do RestApi::Base.new.load_remote_errors(stub(:response => stub(:body => ''))); end
    assert_raise RestApi::BadServerResponseError do RestApi::Base.new.load_remote_errors(stub(:response => stub(:body => ActiveSupport::JSON.encode({})))); end
    assert_raise RestApi::BadServerResponseError do RestApi::Base.new.load_remote_errors(stub(:response => stub(:body => ActiveSupport::JSON.encode({:messages => nil})))); end
    begin
      RestApi::Base.new.load_remote_errors(response(''))
    rescue RestApi::BadServerResponseError => e
      assert_equal '', e.to_s
    end
    begin
      RestApi::Base.new.load_remote_errors(response('{mal'))
    rescue RestApi::BadServerResponseError => e
      assert_equal '{mal', e.to_s
    end
    assert RestApi::Base.new.load_remote_errors(stub(:response => stub(:body => ActiveSupport::JSON.encode({:messages => []})))).empty?
    assert_equal ['hello'], RestApi::Base.new.load_remote_errors(stub(:response => stub(:body => ActiveSupport::JSON.encode({:messages => [{:text => 'hello'}]}))))[:base]
    assert_equal ['hello'], RestApi::Base.new.load_remote_errors(stub(:response => stub(:body => ActiveSupport::JSON.encode({:messages => [{:field => 'test', :text => 'hello'}]}))))[:test]
  end

  class TestExitCodeException < ActiveResource::ConnectionError ; end
  class ExitCode < RestApi::Base
    on_exit_code 124, TestExitCodeException
    on_exit_code 125 do |errors, code, field, text|
      errors.add(:base, "Something awful")
    end
  end

  def test_exit_code_raises
    response = stub(:response => stub(:body => ActiveSupport::JSON.encode({:messages => [{:field => 'test', :text => 'hello', :exit_code => 124}]})))
    assert_raise TestExitCodeException do ExitCode.new.load_remote_errors(response, true, true) end
    assert RestApi::Base.new.load_remote_errors(response, true, true)

    response = stub(:response => stub(:code => 500, :body => ActiveSupport::JSON.encode({:messages => [{:field => 'test', :text => 'hello', :exit_code => 124}]})))
    assert_raise TestExitCodeException do ExitCode.new.load_remote_errors(response, true, true) end

    response = stub(:response => stub(:code => 409, :body => ActiveSupport::JSON.encode({:messages => [{:field => 'test', :text => 'hello', :exit_code => 124}]})))
    assert_raise TestExitCodeException do ExitCode.new.load_remote_errors(response, true, true) end

    response = stub(:response => stub(:body => ActiveSupport::JSON.encode({:messages => [{:field => 'test', :text => 'hello', :exit_code => 123}]})))
    assert RestApi::Base.new.load_remote_errors(response, true, true)
  end

  def test_exit_code_modifies_errors
    response = stub(:response => stub(:body => ActiveSupport::JSON.encode({:messages => [{:field => 'test', :text => 'hello', :exit_code => 125}]})))
    assert (obj = ExitCode.new).load_remote_errors(response, true, true)
    assert_equal obj.errors[:base], ["Something awful"]
    assert (obj = RestApi::Base.new).load_remote_errors(response, true, true)
    assert_equal obj.errors[:test], ["hello"]
  end

  def test_serialization
    app = Application.new :name => 'test1', :cartridge => 'cool', :application_type => 'diy-0.1', :as => @user
    #puts app.class.send('known_attributes').inspect
    app.serializable_hash
  end

  class Calculated < RestApi::Base
    schema do
      string :first, :last
    end
    attr_alters :together, [:first, :last]
    attr_alters :together_nil, [:first, :last]
    def together=(together)
      self.first, self.last = together.split if together
      super
    end
    def together_nil=(together)
      if together
        self.first, self.last = together.split
      else
        self.first = nil
        self.last = nil
      end
      super
    end

    alias_attribute :start, :first

    validates :first, :length => {:maximum => 1},
              :presence => true,
              :allow_blank => false
    validates :last, :length => {:minimum => 2},
              :presence => true,
              :allow_blank => false
  end

  def test_alias_assign
    c = Calculated.new :start => 'a'
    assert_equal 'a', c.start

    c = Calculated.new :start => 'a', :first => nil
    assert_equal nil, c.start

    c = Calculated.new :start => 'a', :first => 'b'
    assert_equal 'b', c.start

    c = Calculated.new :start => nil, :first => 'b'
    assert_equal 'b', c.start
  end

  def test_alias_error
    c = Calculated.new
    c.valid?
    assert_equal ["can't be blank"], c.errors[:first]
    assert_equal ["can't be blank"], c.errors[:start]
  end

  def test_calculated_attr
    c = Calculated.new
    assert_equal 'a b', c.together = 'a b'
    assert_equal 'a b', c.attributes[:together]
    assert_equal 'a', c.first
    assert_equal 'b', c.last

    c = Calculated.new :together => 'a b'
    assert_equal 'a b', c.together
    assert_equal 'a b', c.attributes[:together]
    assert_equal 'a', c.first
    assert_equal 'b', c.last

    c = Calculated.new.load(:together => 'a b')
    assert_equal 'a b', c.together
    assert_equal 'a', c.first
    assert_equal 'b', c.last

    c = Calculated.new :first => 'c', :last => 'd'
    assert_equal 'a b', c.together = 'a b'
    assert_equal 'a', c.first
    assert_equal 'b', c.last

    c = Calculated.new :together => 'a b', :first => 'c', :last => 'd'
    assert_equal 'a', c.first
    assert_equal 'b', c.last

    c = Calculated.new :together => nil, :first => 'c', :last => 'd'
    assert_equal 'c', c.first
    assert_equal 'd', c.last

    c = Calculated.new :together_nil => nil, :first => 'c', :last => 'd'
    assert_nil c.first
    assert_nil c.last
  end

  def test_calculated_errors
    c = Calculated.new :first => 'ab', :last => 'c'
    assert !c.valid?
    assert c.errors[:first].length == 1
    assert c.errors[:last].length == 1
    assert_equal 2, c.errors[:together].length
    assert c.errors[:together].include? c.errors[:first][0]
    assert c.errors[:together].include? c.errors[:last][0]
  end

  class Observed < RestApi::Base
  end

  class Observer < ActiveModel::Observer
    observe RestApiTest::Observed
    def after_save(domain)
      puts "save"
    end
    def after_create(domain)
      puts "create"
    end
  end
  def test_observed
    Observed.observers = Observer
    Observed.instantiate_observers

    Observer.any_instance.expects(:after_save)
    Observer.any_instance.expects(:after_create)
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post '/broker/rest/observeds.json', json_header(true), {}.to_json
    end

    o = Observed.new :as => @user
    o.save
  end

  def test_domain_observed
    assert RestApi::Base.observers.include?(DomainSessionSweeper)
  end

  def test_client_key_validation
    key = Key.new :type => 'ssh-rsa', :name => 'test2', :as => @user
    assert !key.save
    assert_equal 1, key.errors[:content].length

    key.content = ''
    assert !key.save
    assert_equal 1, key.errors[:content].length

    key.content = 'a'

    ActiveResource::HttpMock.respond_to do |mock|
      mock.post '/broker/rest/user/keys.json', json_header(true), key.to_json
    end

    assert key.save
    assert key.errors.empty?
  end

  class ReflectedTest < ActiveResource::Base
    self.site = "http://localhost"
  end

  def test_create_safe_reflected_name
    base = ReflectedTest.new
    r = base.send("find_or_create_resource_for", 'mysql-5.1')
    assert_equal 'RestApiTest::ReflectedTest::Mysql51', r.name, r.pretty_inspect
  end

  def test_create_cookie
    base_connection = ActiveResource::PersistentConnection.new 'http://localhost', :xml
    connection = RestApi::UserAwareConnection.new base_connection, RestApi::Authorization.new('test1', '1234')
    headers = connection.authorization_header(:post, '/something')
    assert_equal 'rh_sso=1234', headers['Cookie']
  end

  def test_reuse_connection
    auth1 = RestApi::Authorization.new('test1', '1234', 'pass1')
    auth2 = RestApi::Authorization.new('test2', '12345', 'pass2')

    assert connection = RestApi::Base.connection(:as => auth1)
    assert connection1 = RestApi::Base.connection(:as => auth1)
    assert connection2 = RestApi::Base.connection(:as => auth2)

    assert_same connection.send(:http), connection1.send(:http)
    assert_same connection.send(:http), connection2.send(:http)

    assert_equal 'test1', connection.user
    assert_equal 'test1', connection1.user
    assert_equal 'test2', connection2.user

    assert_equal auth1.password, connection1.password
    assert_equal auth2.password, connection2.password
  end

  def test_load_returns_self
    key = Key.new
    assert_equal key, key.load({})
  end

  def test_user_get
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/user.json', json_header, { :login => 'test1' }.to_json()
    end

    user = User.find :one, :as => @user
    assert user
    assert_equal @user.login, user.login
  end

  def test_custom_id_rename
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains.json', json_header, [{:id => 'a'}].to_json
      mock.put '/broker/rest/domains/a.json', json_header(true), {:id => 'b'}.to_json
    end

    domain = Domain.first :as => @user
    assert_equal 'a', domain.name
    assert_equal '/broker/rest/domains/a.json', domain.send(:element_path)

    domain.name = 'b'

    assert_equal 'a', domain.instance_variable_get(:@update_id)
    assert_equal 'b', domain.id
    assert_equal 'b', domain.name
    assert_equal '/broker/rest/domains/a.json', domain.send(:element_path)
    assert domain.save

    domain = Domain.first :as => @user
    domain.load({:name => 'b'})

    assert_equal 'a', domain.instance_variable_get(:@update_id)
    assert_equal 'b', domain.id
    assert_equal 'b', domain.name
    assert_equal '/broker/rest/domains/a.json', domain.send(:element_path)
  end

  class DomainWithValidation < Domain
    self.element_name = 'domain'
    validates :id, :length => {:maximum => 1},
              :presence => true,
              :allow_blank => false
  end

  def test_custom_id_rename_with_validation
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains.json', json_header, [{:id => 'a'}].to_json
      mock.put '/broker/rest/domains/a.json', json_header(true), {:id => 'b'}.to_json
    end
    t = DomainWithValidation.first :as => @user
    assert_nil t.instance_variable_get(:@update_id)

    t.name = 'ab'
    assert !t.save, t.pretty_inspect
    assert_equal 'a', t.instance_variable_get(:@update_id)

    t.name = 'b'
    assert t.save
    assert_nil t.instance_variable_get(:@update_id)
  end

  def test_key_make_unique_noop
    key = Key.new :name => 'key'
    key.instance_variable_set :@persisted, true
    key.instance_variable_set :@update_id, key.name
    key.expects(:connection).never.expects(:as).never
    assert_equal 'key', key.make_unique!.name
  end

  def test_key_make_unique
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/user/keys.json', json_header, [].to_json
    end
    assert_equal 'key', Key.new(:name => 'key', :as => @user).make_unique!.name
    assert_equal 'key', Key.new(:name => 'key', :as => @user).make_unique!('key %s').name

    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/user/keys.json', json_header, [{:name => 'key'}].to_json
    end
    assert_equal 'key 2', Key.new(:name => 'key', :as => @user).make_unique!.name
    assert_equal 'new key 2', Key.new(:name => 'key', :as => @user).make_unique!('new key %s').name

    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/user/keys.json', json_header, [{:name => 'key'}, {:name => 'key 2'}].to_json
    end
    assert_equal 'key 3', Key.new(:name => 'key', :as => @user).make_unique!.name
    assert_equal 'new key 2', Key.new(:name => 'key', :as => @user).make_unique!('new key %s').name
  end

  def test_key_attributes
    key = Key.new
    assert_nil key.name
    assert_nil key.content
    assert_nil key.raw_content
    assert_nil key.type

    key.name = 'a'
    assert_equal key.name, key.to_param

    key.raw_content = 'ssh-rsa key'
    assert_equal 'ssh-rsa', key.type
    assert_equal 'key', key.content

    key = Key.new :raw_content => 'ssh-rsa key'
    assert_equal 'ssh-rsa', key.type
    assert_equal 'key', key.content

    key = Key.new :raw_content => 'ssh-rsa key', :type => 'fish'
    assert_equal 'ssh-rsa', key.type
    assert_equal 'key', key.content

    key = Key.new :raw_content => 'ssh-rsa key test'
    assert_equal 'ssh-rsa', key.type
    assert_equal 'key', key.content

    key = Key.new :raw_content => 'ssh-dss key test'
    assert_equal 'ssh-dss', key.type
    assert_equal 'key', key.content

    key = Key.new :raw_content => 'ssh-rs key'
    assert_nil key.type
    assert_equal 'ssh-rs', key.content
  end

  def test_domain_throws_on_find_one
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains.json', json_header, [].to_json
    end

    assert_nil Domain.first :as => @user
    assert_raise ActiveResource::ResourceNotFound do
      Domain.find :one, :as => @user
    end
  end

  def test_domain_find_one
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains.json', json_header, [{:id => 'a'}].to_json
    end

    assert Domain.first :as => @user
    assert Domain.find :one, :as => @user
  end

  def test_domain_reload
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains.json', json_header, [{:id => 'a'}].to_json
      mock.get '/broker/rest/domains/a.json', json_header, {:id => 'a'}.to_json
    end
    domain = Domain.find :one, :as => @user
    oldname = domain.name
    domain.name = 'foo'
    assert_equal 'foo', domain.name
    domain.reload
    assert_equal oldname, domain.name
  end

  def test_domain_names
    domain = Domain.new
    assert_nil domain.name
    assert_nil domain.name
    assert !domain.changed?
    domain.name = '1'
    assert domain.changed?
    assert domain.id_changed?
    assert_equal '1', domain.id
    assert_equal '1', domain.name, domain.name
    assert_equal '1', domain.to_param
    domain.name = '2'
    # id should only change on either first update  or save
    assert_equal '2', domain.id
    assert_equal '2', domain.name
    assert_equal '1', domain.to_param
    domain.name = '3'
    assert_equal '3', domain.id
    assert_equal '1', domain.to_param

    domain = Domain.new :name => 'hello'
    assert_equal 'hello', domain.name, domain.name

    domain = Domain.new :name => 'hello'
    assert_equal 'hello', domain.name, domain.name
  end

  def test_domain_assignment_to_application
    app = Application.new :domain_name => '1'
    assert_equal '1', app.domain_id, app.pretty_inspect
    assert_equal '1', app.domain_name

    app = Application.new :domain_id => '1'
    assert_equal '1', app.domain_id, app.domain_name

    app = Application.new :as => @user
    assert_nil app.domain_id
    assert_nil app.domain_name

    app.domain_id = 'test'
    assert_equal 'test', app.domain_id, app.domain_name

    app.domain_name = 'test2'
    assert_equal 'test2', app.domain_id, app.domain_name
  end

  def test_domain_object_assignment_to_application
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains/test3.json', json_header, { :id => 'test3' }.to_json()
    end

    app = Application.new :as => @user
    domain = Domain.new :name => 'test3'

    app.domain_name = domain.name
    assert_equal domain, app.domain

    app = Application.new :as => @user
    app.domain = domain
    assert_equal domain.name, app.domain_id
    assert_equal domain.name, app.domain_name
    assert_equal domain.name, domain.id
  end

  def opts1() {:name => 'app1', :cartridge => 'php-5.3'} ; end
  def opts2() {:name => 'app2', :cartridge => 'php-5.3'} ; end
  def app1() Application.new({:as => @user}.merge(opts1)) ; end
  def app2() Application.new({:as => @user}.merge(opts2)) ; end

  def test_domain_applications
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains.json', json_header, [{ :id => 'a' }].to_json
      mock.get '/broker/rest/domains/a/applications.json', json_header, [opts1, opts2].to_json
    end

    domain = Domain.find :one, :as => @user

    apps = domain.applications
    assert_attr_equal [app1, app2], apps
  end

  def test_domain_applications_reload
    with_apps = lambda do |mock|
      mock.get '/broker/rest/domains.json', json_header, [{ :id => 'a' }].to_json
      mock.get '/broker/rest/domains/a.json', json_header, { :id => 'a' }.to_json
      mock.get '/broker/rest/domains/a/applications.json', json_header, [opts1, opts2].to_json
    end

    ActiveResource::HttpMock.respond_to &with_apps
    domain = Domain.find :one, :as => @user

    cache = states('cache').starts_as('empty')
    Application.expects(:find).once.returns([Application.new(opts1), Application.new(opts2)]).then(cache.is('full'))
    Application.expects(:find).never.when(cache.is('full'))

    domain.expects(:reload).once.then(cache.is('empty'))

    assert apps = domain.applications
    assert_attr_equal [app1, app2], apps

    assert_attr_equal [app1, app2], domain.applications

    domain.reload

    assert_equal [app1, app2], domain.applications
  end

  def test_domain_find_applications
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains.json', json_header, [{ :id => 'a' }].to_json
      mock.get '/broker/rest/domains/a/applications/app1.json', json_header, opts1.to_json
      mock.get '/broker/rest/domains/a/applications/app2.json', json_header, opts2.to_json
      mock.get '/broker/rest/domains/a/applications/app3.json', json_header, nil, 404
    end

    domain = Domain.find :one, :as => @user
    assert_attr_equal app1, domain.find_application('app1')
    assert_attr_equal app2, domain.find_application('app2')
    assert_raise ActiveResource::ResourceNotFound do
      domain.find_application 'app3'
    end
  end

  def test_cartridges
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/cartridges/embedded', json_header
    end

    app = Application.new :name => 'testapp1', :as => @user
    domain = Domain.new :name => 'test3'
    app.domain = domain

    cart = Cartridge.new
    cart.application = app

    assert_equal '/broker/rest/domains/test3/applications/testapp1/cartridges.json', cart.send(:collection_path)
  end

  def test_cartridge_assignment
    cart = Cartridge.new
    app = Application.new :name => 'testapp1', :domain_name => 'test3'
    cart.application = app

    assert_equal '/broker/rest/domains/test3/applications/testapp1/cartridges.json', cart.send(:collection_path)
  end

  def test_cartridge_initialization_object
    app = Application.new :name => 'testapp1', :domain_id => 'test3'
    cart = Cartridge.new :application => app

    assert_equal app.name, cart.application_name

    Application.expects(:find).with(app.name, :params => {:domain_id => app.domain_id}, :as => nil).returns(app)
    assert_equal app.name, cart.application.name

    assert_equal '/broker/rest/domains/test3/applications/testapp1/cartridges.json', cart.send(:collection_path)
  end

  def test_cartridge_assignment_object
    app = Application.new :name => 'testapp1', :domain_id => 'test3'
    cart = Cartridge.new
    cart.application = app

    assert_equal app.name, cart.application_name

    Application.expects(:find).with(app.name, :params => {:domain_id => app.domain_id}, :as => nil).returns(app)
    assert_equal app.name, cart.application.name

    assert_equal '/broker/rest/domains/test3/applications/testapp1/cartridges.json', cart.send(:collection_path)
  end

  def test_gear_assigns_as
    [Domain, Application, Key, Cartridge, Gear].each do |klass|
      assert_equal @user, klass.new(:as => @user).send(:as)
    end
    [Domain, Application, Key, Cartridge, Gear].each do |klass|
      (obj = klass.new).as = @user
      assert_equal @user, obj.send(:as)
    end
  end

  def test_app_domain_assignment_transfers_as
    app = Application.new :domain => Domain.new(:id => '1', :as => @user)
    assert_equal @user, app.send(:as)
  end

  def test_app_cart_assignment_transfers_as
    cart = Cartridge.new :application => Application.new(:as => @user)
    assert_equal @user, cart.send(:as)
  end

  def test_app_domain_object_assignment
    domain = Domain.new :id => "1"
    app = Application.new :name => 'testapp1', :domain => domain
    assert_equal domain.id, app.domain_id
    assert_equal '/broker/rest/domains/1/applications/testapp1.json', app.send(:element_path)

    app = Application.new :name => 'testapp1'
    app.domain = domain
    assert_equal domain.id, app.domain_id
    assert_equal '/broker/rest/domains/1/applications/testapp1.json', app.send(:element_path)
  end

  def test_app_custom_get_method
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains/1/applications/testapp1/gears.json', json_header, [
        { :uuid => 'abc', :components => [ { :name => 'ruby-1.8' } ] },
      ].to_json
    end
    app = Application.new :name => 'testapp1', :domain => Domain.new(:id => '1', :as => @user)
    assert 1, (gears = app.gears).length
    assert 'abc', (gear = gears[0]).uuid
    assert 1, gear.components.length
    assert 'ruby-1.8', gear.components[0].name
  end

  def test_domain_id_tracks_changes
    d = Domain.new :id => '1'
    assert !d.changed?, d.pretty_inspect

    d.id = '2'
    assert d.changed?

    d.id = '1'
    assert d.changed?

    d.changed_attributes.clear
    assert !d.changed?
  end

  def test_domain_update_id_reset
    ActiveResource::HttpMock.respond_to do |mock|
      mock.post '/broker/rest/domains.json', {'Content-Type' => 'application/json'}.merge!(@auth_headers), {:id => '1'}.to_json
      mock.put '/broker/rest/domains/1.json', {'Content-Type' => 'application/json'}.merge!(@auth_headers), {:id => '2'}.to_json
    end
    d = Domain.create :id => '1', :as => @user
    assert !d.changed?, d.pretty_inspect

    d.id = '2'
    assert_equal '1', d.instance_variable_get(:@update_id)
    assert d.save
    assert_equal '2', d.id
  end

  def test_cartridge_type_init
    type = CartridgeType.new :name => 'haproxy-1.4', :display_name => 'Test - haproxy', :website => 'test'

    # custom attributes
    assert 'Test - haproxy', type.display_name
    assert 'haproxy-1.4', type.name
    assert type.name, type.id
    assert 'test', type.website

    # default values
    assert [:embedded], type.type
    assert '1.4', type.version
  end

  def test_cartridge_type_find
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/cartridges.json', json_header, [
        {:name => 'haproxy-1.4'},
      ].to_json
    end
    type = CartridgeType.find 'haproxy-1.4', :as => @user

    # custom attributes
    assert 'Test - haproxy', type.display_name
    assert 'haproxy-1.4', type.name
    assert type.name, type.id
    assert 'test', type.website

    # default values
    assert [:embedded], type.type
    assert '1.4', type.version
  end

  class CacheableRestApi < RestApi::Base
    include RestApi::Cacheable

    @count = 0
    def self.find_single(*args)
      #puts "find_single: #{caller.join("\n  ")}"
      @count += 1
    end
    cache_method :find_single, lambda{ |id, *args| [CacheableRestApi.name, :item, id] }

    def self.find_every(*args)
      #puts "find_every: #{caller.join("\n  ")}"
      @count += 1
    end
    cache_method :find_every, [CacheableRestApi.name, :find_every]

    def self.count
      @count
    end
  end
  class UncacheableRestApi < RestApi::Base
  end

  def test_cacheable_resource
    Rails.cache.clear

    assert CacheableRestApi.respond_to? :cached
    cached = CacheableRestApi.cached
    assert !CacheableRestApi.equal?(cached)
    assert cached < CacheableRestApi
    assert_equal CacheableRestApi.name, cached.name
    assert_equal [:find_every, :find_single], cached.send(:cache_options)[:caches].keys.map(&:to_s).sort.map(&:to_sym)

    assert_same cached, cached.cached

    assert_equal 0, CacheableRestApi.count
    cached.find 1, :as => @user
    assert_equal 1, CacheableRestApi.count
    cached.find 1, :as => @user
    assert_equal 1, CacheableRestApi.count

    cached.all :as => @user
    assert_equal 2, CacheableRestApi.count
    cached.all :as => @user
    assert_equal 2, CacheableRestApi.count
    cached.all :as => RestApi::Authorization.new('different')
    assert_equal 2, CacheableRestApi.count

    assert !UncacheableRestApi.respond_to?(:cached)
  end

  def test_cacheable_key_for
    assert_equal [CacheableRestApi.name, :item, 1], CacheableRestApi.send(:cache_key_for, :find_single, 1)
    assert_equal [CacheableRestApi.name, :item, 2], CacheableRestApi.send(:cache_key_for, :find_single, 2)
    assert_equal [CacheableRestApi.name, :find_every], CacheableRestApi.send(:cache_key_for, :find_every)
  end

  def test_cartridge_type_find_invalid
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/cartridges.json', json_header, [
        {:name => 'haproxy-1.4'},
      ].to_json
    end

    type = CartridgeType.new :name => 'haproxy-1.5', :as => @user
    assert_equal 'haproxy-1.5', type.name
    assert_equal 'haproxy-1.5', type.display_name
  end

  def test_cartridge_delegate_type
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/cartridges.json', json_header, [
        {:name => 'haproxy-1.4'},
      ].to_json
    end

    cart = Cartridge.new :name => 'haproxy-1.4', :as => @user
    assert_equal cart.display_name, CartridgeType.find(cart.name, :as => @user).display_name
    assert cart.instance_variable_get(:@cartridge_type)

    cart = Cartridge.new :name => 'haproxy-1.5', :as => @user
    assert_equal 'haproxy-1.5', cart.display_name
  end

  def test_dup
    d = Domain.new :id => 1, :as => @user
    d2 = d.dup
    assert_same d.send(:as), d2.send(:as)
    assert_same d.id, d2.id
  end

  def test_clone
    d = Domain.new :id => 1, :as => @user
    d2 = d.clone
    assert_same d.send(:as), d2.send(:as)
  end

  def test_custom_id_must_be_valid
    assert_raise(RuntimeError) { Class.new(RestApi::Base) { custom_id "string" } }
    assert_raise(RuntimeError) { Class.new(RestApi::Base) { custom_id Class } }
    assert_raise(RuntimeError) { Class.new(RestApi::Base) { custom_id nil } }
  end

  def test_cartridge_type_category_sort
    [
      [ 1,  [:database],  [:web]],
      [ 1,  [:foo],       [:web]],
      [ 1,  [:foo],       [:database]],
      [ 0,  [:web],       [:web]],
      [ 0,  [:database],  [:database]],
      [ 0,  [:foo],       [:bar]],
      [-1,  [:web],       [:database]],
      [-1,  [:web],       [:foo]],
    ].each do |val, a, b|
      assert_equal val, CartridgeType.category_compare(a, b)
    end
  end

  def test_cartridge_compare
    mock_types

    ruby = CartridgeType.new :name => 'ruby-1.8'
    php = CartridgeType.new :name => 'php-5.3'
    mongo = CartridgeType.new :name => 'mongodb-2.0'
    cron = CartridgeType.new :name => 'cron-1.4'
    jenkins = CartridgeType.new :name => 'jenkins-client-1.4'

    assert cron > ruby
    assert ruby < cron

    assert mongo < cron
    assert cron > mongo

    assert ruby < mongo
    assert mongo > ruby

    assert php < ruby
    assert ruby > php

    assert php < jenkins
    assert ruby < jenkins
  end

  def test_cartridge_type_embedded
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/cartridges.json', json_header, [
        {:name => 'haproxy-1.4', :type => 'embedded'},
      ].to_json
    end

    types = CartridgeType.embedded :as => @user

    assert_equal 1, types.length

    assert types.none?(&:standalone?)
    assert types.all?(&:embedded?)

    assert type = types.find {|t| t.name == 'haproxy-1.4'}
    assert_equal :embedded, type.type
    assert type.embedded?
    assert !type.standalone?
    assert_equal '1.4', type.version
    assert_equal CartridgeType.new(:name => 'haproxy-1.4'), type
    assert_equal 'haproxy-1.4', type.to_param
  end

  def test_cartridge_type_embedded_cached
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/cartridges.json', json_header, [
        {:name => 'haproxy-1.4'},
      ].to_json
    end

    Rails.cache.clear
    key = CartridgeType.send(:cache_key_for, :all)
    assert_nil Rails.cache.read(key)

    types = CartridgeType.embedded :as => @user
    assert_nil Rails.cache.read(key), "Having the regular call fill the cache may be desirable"

    types = CartridgeType.cached.embedded :as => @user
    assert cached = Rails.cache.read(key)

    ActiveResource::HttpMock.reset!
    assert type = CartridgeType.cached.find('haproxy-1.4')
    assert_equal 'haproxy-1.4', type.name
    assert_nil type.send(:as)
  end

  def test_application_types
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/cartridges.json', json_header, [
        {:name => 'haproxy-1.4', :type => 'standalone'},
        {:name => 'php-5.3', :type => 'standalone', :categories => [:framework]},
        {:name => 'blacklist', :type => 'standalone', :categories => [:framework, :blacklist]},
      ].to_json

      mock.get '/broker/rest/application_template.json', json_header, [
      ].to_json
    end
    types = ApplicationType.find :all, :as => @user
    assert_equal 1, types.length, types.inspect
    types.each do |type|
      assert a = ApplicationType.find(type.id, :as => @user)
      assert_equal type.id, a.id
      assert_equal type.description, a.description
      assert_equal type.categories, a.categories
    end

    assert_raise(ApplicationType::NotFound) { ApplicationType.find('blacklist', :as => @user) }
  end

  def test_application_templates
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/cartridges.json', json_header, [
      ].to_json

      mock.get '/broker/rest/application_template.json', json_header, [
        { :name => 'blacklist', :tags => [:framework, :blacklist] },
        {
          :name => 'rails',
          :tags => [:framework, :ruby, :rails],
          :descriptor_yaml => YAML.dump({
            'Name' => "rails"
          }),
          :metadata => {
            :attributes => {
            }.to_json
          },
          :display_name => "Ruby on Rails",
          :uuid => '1234'
        }
      ].to_json
    end

    types = ApplicationType.find :all, :as => @user
    assert_equal 1, types.length

    types.each do |type|
      assert a = ApplicationType.find(type.id, :as => @user)
      assert_equal type.id, a.id
      assert_equal type.description, a.description
      assert_equal type.categories, a.categories
    end

    assert_raise(ApplicationType::NotFound) { ApplicationType.find('blacklist', :as => @user) }
  end

  def test_application_job_url
    a = Application.new :embedded => {'jenkins-client-1.4' => {:info => "Job URL: https://test/test\n"}}
    assert_equal 'https://test/test', a.build_job_url
    assert a.builds?

    a = Application.new :embedded => {'jenkins-client-1.4' => {:info => "Job URL: https://test/test"}}
    assert_equal 'https://test/test', a.build_job_url
    assert a.builds?

    a = Application.new :embedded => {'jenkins-client-1.4' => {}}
    assert_nil a.build_job_url
    assert !a.builds?

    a = Application.new :embedded => {}
    assert_nil a.build_job_url
    assert !a.builds?

    a = Application.new
    assert_nil a.build_job_url
    assert !a.builds?
  end

  def test_get_gear_groups
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains/test/applications/test/gear_groups.json', json_header, [
        {:name => '@@app/comp-web/php-5.3', :gears => [
          {:id => 1, :state => 'started'}
        ], :cartridges => [
          {:name => 'php-5.3'},
        ]},
        {:name => '@@app/comp-proxy/php-5.3', :gears => [
          {:id => 2, :state => 'started'},
        ], :cartridges => [
          {:name => 'php-5.3'},
          {:name => 'haproxy-1.4'},
        ]},
        {:name => '@@app/comp-mysql/mysql-5.0', :gears => [
          {:id => 3, :state => 'started'},
        ], :cartridges => [
          {:name => 'my-sql-5.0'},
        ]},
      ].to_json
    end
    mock_types

    app = Application.new :name => 'test', :domain_id => 'test', :git_url => 'http://localhost', :as => @user
    assert groups = app.gear_groups
    assert cart1 = groups[0].cartridges[0]
    assert_equal 2, groups.length # collapsed by simplify
    assert_same @user, groups[0].send(:as)
    assert_same @user, groups[1].send(:as)
    assert_same @user, cart1.send(:as)

    assert_equal app.git_url, cart1.git_url

    assert cart1.scales?
    assert cart1.scales
    assert_equal 'haproxy-1.4', cart1.scales.with
    assert_equal '@@app/comp-proxy/php-5.3', cart1.scales.on

    assert !groups[1].cartridges[0].scales?
    assert groups[1].cartridges[0].scales
    assert_nil groups[1].cartridges[0].scales.with
    assert_nil groups[1].cartridges[0].scales.on
  end

  def test_cartridge_buildable
    t = CartridgeType.new :name => 'test', :categories => []
    c = Cartridge.new :name => 'test', :as => @user
    c.instance_variable_set(:@cartridge_type, t)
    assert !c.buildable?
    t.categories.push(:web)
    assert !c.buildable?
    c.git_url = 'https://localhost'
    assert c.buildable?
    t.categories.clear
    assert !c.buildable?
  end

  def test_get_gear_groups_with_simple_jenkins
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains/test/applications/test/gear_groups.json', json_header, [
        {:name => '@@app/comp-web/php-5.3', :gear_profile => :medium, :gears => [
          {:id => 1, :state => 'started'}
        ], :cartridges => [
          {:name => 'php-5.3'},
        ]},
        {:name => '@@app/comp-proxy/php-5.3', :gear_profile => :small, :gears => [
          {:id => 2, :state => 'started'},
        ], :cartridges => [
          {:name => 'haproxy-1.4'},
          {:name => 'php-5.3'},
        ]},
      ].to_json
    end
    mock_types

    app = Application.new :name => 'test', :domain_id => 'test', :git_url => 'http://localhost', :as => @user
    assert groups = app.gear_groups
    assert cart1 = groups[0].cartridges[0]
    assert_equal 1, groups.length # collapsed by simplify
    assert_same @user, groups[0].send(:as)
    assert_same @user, cart1.send(:as)

    assert_equal app.git_url, cart1.git_url

    assert_equal 'php-5.3', cart1.name
    assert_equal 1, groups[0].cartridges.length, groups[0].pretty_inspect
    assert !cart1.builds?, groups.pretty_inspect
    assert cart1.buildable?
    assert cart1.builds
    assert_nil cart1.builds.with
    assert_nil cart1.builds.on

    assert cart1.scales?
    assert cart1.scales
    assert_equal 'haproxy-1.4', cart1.scales.with
    assert_equal '@@app/comp-proxy/php-5.3', cart1.scales.on

    assert_equal 1, cart1.gear_count
    assert_equal 1, cart1.gears[0].id
    assert_equal :medium, cart1.gears[0].gear_profile

    assert_equal [Gear.new(:id => 1, :gear_profile => :medium), Gear.new(:id => 2, :gear_profile => :small)], groups[0].gears
  end

  def test_get_gear_groups_with_jenkins
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains/test/applications/test/gear_groups.json', json_header, [
        {:name => '@@app/comp-web/php-5.3', :gear_profile => :medium, :gears => [
          {:id => 1, :state => 'started'}
        ], :cartridges => [
          {:name => 'php-5.3'},
        ]},
        {:name => '@@app/comp-proxy/php-5.3', :gear_profile => :small, :gears => [
          {:id => 2, :state => 'started'},
        ], :cartridges => [
          {:name => 'jenkins-client-1.4'},
          {:name => 'haproxy-1.4'},
          {:name => 'php-5.3'},
        ]},
      ].to_json
    end
    mock_types

    app = Application.new :name => 'test', :domain_id => 'test', :git_url => 'http://localhost', :as => @user
    assert groups = app.gear_groups
    assert cart1 = groups[0].cartridges[0]
    assert_equal 1, groups.length # collapsed by simplify
    assert_same @user, groups[0].send(:as)
    assert_same @user, cart1.send(:as)

    assert_equal app.git_url, cart1.git_url

    assert_equal 'php-5.3', cart1.name
    assert_equal 1, groups[0].cartridges.length
    assert cart1.builds?, groups.pretty_inspect
    assert cart1.builds
    assert cart1.buildable?
    assert_equal 'jenkins-client-1.4', cart1.builds.with.name
    assert_equal '@@app/comp-proxy/php-5.3', cart1.builds.on

    assert cart1.scales?
    assert cart1.scales
    assert_equal 'haproxy-1.4', cart1.scales.with
    assert_equal '@@app/comp-proxy/php-5.3', cart1.scales.on

    assert_equal 1, cart1.gear_count
    assert_equal 1, cart1.gears[0].id
    assert_equal :medium, cart1.gears[0].gear_profile

    assert_equal [Gear.new(:id => 1, :gear_profile => :medium), Gear.new(:id => 2, :gear_profile => :small)], groups[0].gears
  end

  def test_get_gear_groups_with_jenkins_and_db
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains/test/applications/test/gear_groups.json', json_header, [
        {:name => '@@app/comp-web/php-5.3', :gear_profile => :medium, :gears => [
          {:id => 1, :state => 'started'}
        ], :cartridges => [
          {:name => 'php-5.3'},
        ]},
        {:name => '@@app/comp-proxy/php-5.3', :gear_profile => :small, :gears => [
          {:id => 2, :state => 'started'},
        ], :cartridges => [
          {:name => 'jenkins-client-1.4'},
          {:name => 'haproxy-1.4'},
          {:name => 'php-5.3'},
          {:name => 'mysql-5.1'},
        ]},
      ].to_json
    end
    mock_types

    app = Application.new :name => 'test', :domain_id => 'test', :git_url => 'http://localhost', :as => @user
    assert groups = app.gear_groups
    assert_equal 2, groups.length # mysql is the only cart left on group 2

    assert cart1 = groups[0].cartridges[0]

    assert_equal app.git_url, cart1.git_url

    assert_equal 'php-5.3', cart1.name
    assert_equal 1, groups[0].cartridges.length
    assert cart1.builds?, groups.pretty_inspect
    assert cart1.builds
    assert cart1.buildable?
    assert_equal 'jenkins-client-1.4', cart1.builds.with.name
    assert_equal '@@app/comp-proxy/php-5.3', cart1.builds.on

    assert cart1.scales?
    assert cart1.scales
    assert_equal 'haproxy-1.4', cart1.scales.with
    assert_equal '@@app/comp-proxy/php-5.3', cart1.scales.on

    assert_equal 1, cart1.gear_count
    assert_equal 1, cart1.gears[0].id
    assert_equal :medium, cart1.gears[0].gear_profile

    assert_equal [Gear.new(:id => 1, :gear_profile => :medium)], groups[0].gears

    assert_equal 1, groups[1].cartridges.length
    assert cart2 = groups[1].cartridges[0]
    assert_equal 'mysql-5.1', cart2.name
    assert !cart2.scales?
    assert !cart2.builds?

    assert_equal [Gear.new(:id => 2, :gear_profile => :small)], groups[1].gears
  end

  def test_gear_group_merge
    gear1 = Gear.new :id => 1, :state => 'started'
    gear2 = Gear.new :id => 2, :state => 'started'
    gear3 = Gear.new :id => 3, :state => 'started'
    cart_a = Cartridge.new :name => 'a'
    cart_b = Cartridge.new :name => 'b'
    cart_c = Cartridge.new :name => 'c'
    group1 = GearGroup.new({:name => 'group1', :gears => [gear1], :cartridges => [cart_a]})
    orig1  = GearGroup.new({:name => 'group1', :gears => [gear1], :cartridges => [cart_a]})
    group2 = GearGroup.new({:name => 'group2', :gears => [gear2, gear3], :cartridges => [cart_b, cart_c]})

    assert group1.equal?(group1)
    assert group1.merge(group1)
    assert_equal orig1.cartridges, group1.cartridges
    assert_equal orig1.gears, group1.gears

    group1.merge(group2)
    assert_equal [cart_a, cart_b, cart_c], group1.cartridges
    assert_equal [gear1, gear2, gear3], group1.gears
  end

  def test_gear_group_move_features
    mock_types

    gear1 = Gear.new :id => 1, :state => 'started'
    cart_build = Cartridge.new :name => 'jenkins-client-1.4'
    cart_web = Cartridge.new :name => 'php-5.3'
    group1 = GearGroup.new({:name => 'group1', :gears => [gear1], :cartridges => [cart_build]}, :as => @user)

    group2 = GearGroup.new(:cartridges => [cart_web])

    assert !group1.send(:move_features, group1)

    assert group1.send(:move_features, group2)
    assert group1.gears.empty?
    assert group1.cartridges.empty?
    assert_equal 1, group2.gears.length
    assert group2.cartridges[0].builds?
    assert group2.cartridges[0].builds
    assert_equal cart_build, group2.cartridges[0].builds.with
    assert_equal group1.name, group2.cartridges[0].builds.on

    assert group1.send(:move_features, group2) # nothing is moved, but group1 is still empty and should be purged
  end

  def test_gear_group_simplify
    mock_types

    gear1 = Gear.new :id => 1, :state => 'started'
    cart_a = Cartridge.new :name => 'a'
    groups = [
      GearGroup.new({:name => 'group1', :gears => [gear1], :cartridges => [cart_a]}),
    ]
    app = Application.new :git_url => 'http://localhost'
    new_groups = GearGroup.simplify(groups, app)

    assert_equal 1, new_groups.length
    assert_equal [gear1], new_groups[0].gears
    assert_equal [cart_a], new_groups[0].cartridges
  end

  def test_gear_group_simplify_scaled_zero
    mock_types

    gear1 = Gear.new :id => 1, :state => 'started'
    gear2 = Gear.new :id => 2, :state => 'started'
    gear3 = Gear.new :id => 3, :state => 'started'
    cart_a = Cartridge.new :name => 'a'
    cart_b = Cartridge.new :name => 'php-5.3' #only cartridges with category :web scale
    cart_c = Cartridge.new :name => 'c'
    cart_proxy = Cartridge.new :name => 'haproxy-1.4'
    groups = [
      GearGroup.new({:name => 'group1', :gears => [gear1], :cartridges => [cart_a]}),
      GearGroup.new({:name => 'group2', :gears => [gear2], :cartridges => [cart_b, cart_proxy]}),
      GearGroup.new({:name => 'group3', :gears => [gear3], :cartridges => [cart_c]}),
    ]
    app = Application.new :git_url => 'http://localhost'
    new_groups = GearGroup.simplify(groups, app)

    assert_equal 3, new_groups.length, new_groups.pretty_inspect
    assert 'group2', new_groups[0].name
    assert new_groups[0].scales?
    assert_equal 0, new_groups[0].cartridges[0].scales.times
    assert_equal groups[0], new_groups[1]
    assert_equal groups[2], new_groups[2]
    assert_equal app.git_url, new_groups[0].cartridges[0].git_url
    assert_nil new_groups[1].cartridges[0].git_url
  end

  #
  # Prime the cartridge type cache so lookups are valid.  Call after 
  # HttpMock.respond_to or use respond_to(false).
  #
  def mock_types
    types = CartridgeType.send(:known_types).map{ |t| {:name => t[:name]} }
    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.get '/broker/rest/cartridges.json', json_header, types.to_json
    end
    types = CartridgeType.cached.all :as => @user
    assert types.length > 0
    assert Rails.cache.read(CartridgeType.send(:cache_key_for, :all))
    types
  end

  def test_gear_group_simplify_reorders
    mock_types
    gear1 = Gear.new :id => 1, :state => 'started'
    gear2 = Gear.new :id => 2, :state => 'started'
    gear3 = Gear.new :id => 3, :state => 'started'
    cart_db1 = Cartridge.new :name => 'mongodb-2.0'
    cart_db2 = Cartridge.new :name => 'mysql-5.1'
    cart_web = Cartridge.new :name => 'php-5.3'
    groups = [
      GearGroup.new({:name => 'group1', :gears => [gear1], :cartridges => [cart_db1]}),
      GearGroup.new({:name => 'group2', :gears => [gear2], :cartridges => [cart_db2]}),
      GearGroup.new({:name => 'group3', :gears => [gear3], :cartridges => [cart_web]}),
    ]
    app = Application.new :git_url => 'http://localhost'
    new_groups = GearGroup.simplify(groups, app)

    assert_equal 3, new_groups.length, new_groups.pretty_inspect
    assert_equal cart_web.name, new_groups[0].cartridges[0].name
    assert_equal cart_db1.name, new_groups[1].cartridges[0].name
    assert_equal cart_db2.name, new_groups[2].cartridges[0].name
  end

  def test_destroy_build_cartridge
    app = Application.new({:domain_id => 'foo', :as => @as, :name => 'me'}, true)
    Cartridge.any_instance.expects(:destroy).returns(true)
    assert app.destroy_build_cartridge
  end

  def test_destroy_build_cartridge_failures
    app = Application.new({:domain_id => 'foo', :as => @as, :name => 'me'}, true)
    Cartridge.any_instance.expects(:destroy).raises(ActiveResource::ServerError.new(stub))
    assert_raise(ActiveResource::ServerError) { app.destroy_build_cartridge }
  end
end
