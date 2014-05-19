ENV["TEST_NAME"] = "unit_authentication_test"
require File.expand_path('../../test_helper', __FILE__)

class AuthenticationTest < ActiveSupport::TestCase

  Controller = Class.new(ActionController::Metal) do
    include Test::Unit::Assertions
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    def self.helper_method(*args)
      (@helper_method ||= []).concat(args)
    end
    def render_exception(e)
      raise e
    end
    def render_error(*args)
      raise args.inspect
    end
    def request
      @request ||= ActionDispatch::TestRequest.new
    end
    def response
      @response ||= ActionDispatch::TestResponse.new
    end
    def auth_service
      @auth_service ||= SimpleAuthService.new
    end

    def log_actions_as(user)
      @log_actions_as = user
    end
    def log_action(*args)
      (@log_actions ||= []) << [nil, @log_actions_as ? @log_actions_as.login : nil, @log_actions_as ? @log_actions_as.id : nil, *args]
    end
    def log_action_for(login, id, *args)
      (@log_actions ||= []) << [:for, login, id, *args]
    end
    def assert_log_action?(action, message=nil)
      assert a = @log_actions.find{ |a| a[3] == action }
      assert a[6].include?(message) if message.is_a?(String)
      assert message.match(a[6]) if message.is_a?(Regexp)
    end

    attr_writer :auth_service

    include OpenShift::Controller::Authentication
  end

  class LegacyAuthService
    def authenticate(request, login, password)
      _authenticate(request, login, password)
    end
  end
  class SimpleAuthService
    def authenticate(login, password)
      _authenticate(login, password)
    end
  end

  setup{ Controller.send(:public, *Controller.protected_instance_methods) }

  def controller
    @controller ||= Controller.new
  end

  def with_credentials(login, password=nil)
    controller.request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(login, password)
  end

  def with_bearer_token(token)
    controller.request.env['HTTP_AUTHORIZATION'] = "Bearer #{token}"
  end

  def with_legacy_auth_service
    controller.auth_service = LegacyAuthService.new
  end

  def assert_not_logged_in
    assert !controller.user_signed_in?
    assert_nil controller.current_user
    assert_nil controller.authenticate_user!
  end

  def assert_logged_in(login_or_user, auth_method=:login)
    if login_or_user.is_a?(String)
      login = login_or_user
      user = CloudUser.new(:login => login)
      user.stubs(:new_record?).returns(false)
      CloudUser.expects(:find_or_create_by_identity).with(nil, login).returns(user, false)
    else
      user = login_or_user
      login = user.login
    end

    assert_same(user, controller.authenticate_user!, "Return value differs")
    assert controller.user_signed_in?, "User is not signed in"
    assert_same(user, controller.current_user, "Users differ")
    assert_equal login, controller.headers['X-OpenShift-Identity']
    controller.assert_log_action?('AUTHENTICATE')
    assert_equal auth_method, user.auth_method
  end

  test 'is not logged in with no credentials' do
    controller.auth_service.expects(:authenticate).never
    controller.expects(:request_http_basic_authentication)

    assert_not_logged_in
  end

  test 'is not logged in when the service returns false' do
    with_credentials('test')
    controller.auth_service.expects(:_authenticate).with('test', '').returns(false)
    controller.expects(:request_http_basic_authentication)

    assert_not_logged_in
  end

  test 'is logged in when the service authenticates' do
    with_credentials('test', 'foo')
    controller.auth_service.expects(:_authenticate).with('test', 'foo').returns({:username => 'test'})

    assert_logged_in('test')
  end

  test 'is logged in when a legacy service authenticates' do
    with_credentials('test', 'foo')
    with_legacy_auth_service
    controller.auth_service.expects(:_authenticate).with(controller.request, 'test', 'foo').returns({:username => 'test'})

    assert_logged_in('test')
  end

  test 'is not logged in when invalid bearer token passed' do
    with_bearer_token('foo')
    Authorization.expects(:authenticate).with('foo').returns(nil)

    controller.expects(:render)
    assert_not_logged_in
    controller.assert_log_action?('AUTHENTICATE', /Access denied by bearer token/)
    controller.headers['WWW-Authenticate'] =~ /Bearer error=invalid_token/
  end

  test 'is not logged in when expired bearer token passed' do
    with_bearer_token('foo')
    token = Authorization.new{ |a| a.id = 'foo' }
    token.expects(:accessible?).returns(false)
    Authorization.expects(:authenticate).with('foo').returns(token)

    controller.expects(:render)
    assert_not_logged_in
    controller.assert_log_action?('AUTHENTICATE', /Access denied by bearer token/)
    controller.headers['WWW-Authenticate'] =~ /Bearer error=invalid_token/
  end

  test 'is logged in when valid bearer token passed' do
    with_bearer_token('foo')
    user = CloudUser.new(:login => 'bar')
    token = Authorization.new{ |a| a.id = 'foo'; a.scopes = Scope.for!('session') }
    token.expects(:accessible?).returns(true)
    token.expects(:user).returns(user)
    Authorization.expects(:authenticate).with('foo').returns(token)

    assert_logged_in(user, :authorization_token)
    assert_equal Scope.list!('session'), controller.current_user_scopes
  end

  test 'forbids write access with read token' do
    with_bearer_token('foo')
    controller.request.expects(:method).returns('POST')
    user = CloudUser.new(:login => 'bar')
    token = Authorization.new{ |a| a.id = 'foo'; a.scopes = Scope.for('read') }
    token.expects(:accessible?).returns(true)
    token.expects(:user).returns(user)
    Authorization.expects(:authenticate).with('foo').returns(token)

    controller.expects(:render_error).with(:forbidden, 'This action is not allowed with your current authorization.', 1)
    controller.authenticate_user!
  end

  test 'forbids general access with userinfo token' do
    with_bearer_token('foo')
    user = CloudUser.new(:login => 'bar')
    token = Authorization.new{ |a| a.id = 'foo'; a.scopes = Scope.for('userinfo') }
    token.expects(:accessible?).returns(true)
    token.expects(:user).returns(user)
    Authorization.expects(:authenticate).with('foo').returns(token)

    controller.expects(:render_error).with(:forbidden, 'This action is not allowed with your current authorization.', 1)
    controller.authenticate_user!
  end

  test 'should read secondary then primary for authorization tokens on authenticate' do
    qualifier = mock
    fully = mock
    s = sequence('load')
    Authorization.expects(:with).with(consistency: :eventual).in_sequence(s).returns(qualifier)
    qualifier.expects(:where).with(:token => 'foo').in_sequence(s).returns(fully)
    fully.expects(:find_by).in_sequence(s).raises(Mongoid::Errors::DocumentNotFound.new(Authorization, nil, ['foo']))
    Authorization.expects(:where).with(:token => 'foo').in_sequence(s).returns([true])

    assert Authorization.authenticate('foo')
  end

  test 'checks broker key auth' do
    user = CloudUser.new(:login => 'bar')
    controller.broker_key_auth.expects(:authenticate_request).with(controller).returns({:user => user, :auth_method => :broker_auth})

    assert_logged_in(user, :broker_auth)
  end
end
