require 'test_helper'
require 'active_resource/http_mock'

#
# Mock tests only - should verify functionality of ActiveResource extensions
# and simple server/client interactions via HttpMock
#
class RestApiTest < ActiveSupport::TestCase

  def setup
  end

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
      mock.get '/domains.json', {'Accept' => 'application/json'}.merge!(@auth_headers), [{ :namespace => 'adomain' }].to_json()
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

  def test_create_cookie
    connection = RestApi::UserAwareConnection.new 'http://localhost', :xml, RestApi::Authorization.new('test1', '1234')
    headers = connection.authorization_header(:post, '/something')
    assert_equal 'rh_sso=1234', headers['Cookie']
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
      mock.get '/broker/rest/domains.json', json_header, [{:namespace => 'a'}].to_json
      mock.put '/broker/rest/domains/a.json', json_header(true), {:namespace => 'b'}.to_json
    end

    domain = Domain.first :as => @user
    assert_equal 'a', domain.name
    assert_equal '/broker/rest/domains/a.json', domain.send(:element_path)

    domain.name = 'b'

    assert_equal 'a', domain.instance_variable_get(:@update_id)
    assert_equal 'a', domain.id
    assert_equal 'b', domain.namespace
    assert_equal '/broker/rest/domains/a.json', domain.send(:element_path)
    assert domain.save

    domain = Domain.first :as => @user
    domain.load({:name => 'b'})

    assert_equal 'a', domain.instance_variable_get(:@update_id)
    assert_equal 'a', domain.id
    assert_equal 'b', domain.namespace
    assert_equal '/broker/rest/domains/a.json', domain.send(:element_path)
  end

  class DomainWithValidation < Domain
    self.element_name = 'domain'
    validates :name, :length => {:maximum => 1},
              :presence => true,
              :allow_blank => false
  end

  def test_custom_id_rename_with_validation
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/domains.json', json_header, [{:namespace => 'a'}].to_json
      mock.put '/broker/rest/domains/a.json', json_header(true), {:namespace => 'b'}.to_json
    end
    t = DomainWithValidation.first :as => @user
    assert_nil t.instance_variable_get(:@update_id)

    t.name = 'ab'
    assert !t.save
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
    assert_equal key.id, key.name

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

  def test_domain_namespaces
    domain = Domain.new
    assert_nil domain.name
    assert_nil domain.namespace
    assert !domain.changed?
    domain.name = '1'
    assert domain.changed?
    assert domain.namespace_changed?
    assert_equal '1', domain.id
    assert_equal '1', domain.name, domain.namespace
    domain.namespace = '2'
    # id should only change on either first update  or save
    assert_equal '1', domain.id
    assert_equal '2', domain.name, domain.namespace
    domain.namespace = '3'
    assert_equal '1', domain.id

    domain = Domain.new :name => 'hello'
    assert_equal 'hello', domain.name, domain.namespace

    domain = Domain.new :namespace => 'hello'
    assert_equal 'hello', domain.name, domain.namespace
  end

  def test_domain_assignment_to_application
    app = Application.new :domain_name => '1'
    assert_equal '1', app.domain_id, app.domain_name

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
      mock.get '/broker/rest/domains/test3.json', json_header, { :namespace => 'test3' }.to_json()
    end

    app = Application.new :as => @user
    domain = Domain.new :name => 'test3'

    app.domain_name = domain.namespace
    assert_equal domain, app.domain

    app = Application.new :as => @user
    app.domain = domain
    assert_equal domain.namespace, app.domain_id, app.domain_name
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
end
