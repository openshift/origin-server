require File.expand_path('../../test_helper', __FILE__)

class ConsoleAuthRemoteUserControllerTest < ActionController::TestCase
  uses_http_mock :sometimes

  class ConsoleAuthRemoteUserController < ActionController::Base
    include Console::Rescue
    include Console::Auth::RemoteUser

    before_filter :authenticate_user!, :except => :unprotected

    def unauthorized_path
      "/unauthorized"
    end

    def protected
      render :status => 200, :nothing => true
    end
    def unprotected
      render :status => 200, :nothing => true
    end
    def restapi
      @user = User.find :one, :as => current_user
      render :status => 200, :nothing => true
    end
  end

  setup{ Rails.application.routes.draw{ match ':action' => ConsoleAuthRemoteUserController } }
  teardown{ Rails.application.reload_routes! }

  setup{ Console.config.expects(:remote_user_header).at_least_once.returns('HTTP_X_REMOTE_USER') }
  setup{ Console.config.stubs(:remote_user_copy_headers).returns(['X-Remote-User','X-Other-Header']) }

  tests ConsoleAuthRemoteUserController

  test 'should redirect when protected' do
    get :protected
    assert_redirected_to @controller.unauthorized_path
  end

  test 'should render when protected' do
    @request.env['HTTP_X_REMOTE_USER'] = 'bob'

    get :protected

    assert_response :success
    assert assigns(:authenticated_user)
    assert_equal 'bob', @controller.current_user.login
    assert_equal 'bob', assigns(:authenticated_user).login

    assert !@controller.current_user.persisted?
    assert @controller.user_signed_in?
    assert !@controller.previously_signed_in?
  end

  test 'should override name configured' do
    Console.config.expects(:remote_user_name_header).at_least_once.returns('HTTP_X_REMOTE_USER_NAME')
    @request.env['HTTP_X_REMOTE_USER'] = 'bob'
    @request.env['HTTP_X_REMOTE_USER_NAME'] = 'alice'

    get :protected

    assert_response :success
    assert assigns(:authenticated_user)
    assert_equal 'alice', @controller.current_user.login
    assert_equal 'alice', assigns(:authenticated_user).login
  end

  test 'should pass headers to REST API' do
    @request.env['HTTP_X_REMOTE_USER'] = 'bob'

    allow_http_mock
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/user.json', anonymous_json_header.merge('X-Remote-User' => 'bob'), {:login => 'foo'}.to_json
    end

    get :restapi
    assert_response :success
    assert user = assigns(:user)
    assert_equal 'foo', user.login
  end

  test 'should redirect when misconfigured' do
    @request.env['HTTP_X_REMOTE_USER'] = 'bob'

    allow_http_mock
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/user.json', anonymous_json_header.merge('X-Remote-User' => 'bob'), nil, 401
    end

    get :restapi
    assert_redirected_to  @controller.unauthorized_path
  end
end
