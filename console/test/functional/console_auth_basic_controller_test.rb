require File.expand_path('../../test_helper', __FILE__)

class ConsoleAuthBasicControllerTest < ActionController::TestCase
  uses_http_mock :sometimes

  class ConsoleAuthBasicController < ActionController::Base
    include Console::Rescue
    include Console::Auth::Basic

    before_filter :authenticate_user!, :except => :unprotected

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

  setup{ Rails.application.routes.draw{ match ':action' => ConsoleAuthBasicController } }
  teardown{ Rails.application.reload_routes! }

  tests ConsoleAuthBasicController

  test 'should challenge when protected' do
    get :protected
    assert_response :unauthorized
  end

  test 'should challenge when username empty' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(nil, 'password')

    get :protected
    assert_response :unauthorized
  end

  test 'should render when protected' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('bob', 'password')

    get :protected

    assert_response :success
    assert assigns(:authenticated_user)
    assert_equal 'bob', @controller.current_user.login
    assert_equal 'bob', assigns(:authenticated_user).login

    assert !@controller.current_user.persisted?
    assert @controller.current_user.email_address.nil?
    assert @controller.user_signed_in?
    assert !@controller.previously_signed_in?
  end

  test 'should pass headers to REST API' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('bob', 'password')

    allow_http_mock
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/user.json', anonymous_json_header.merge('Authorization' => @request.env['HTTP_AUTHORIZATION']), {:login => 'foo'}.to_json
    end

    get :restapi
    assert_response :success
    assert user = assigns(:user)
    assert_equal 'foo', user.login
  end

  test 'should challenge when broker rejects password' do
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('bob', 'password')

    allow_http_mock
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/broker/rest/user.json', anonymous_json_header.merge('Authorization' => @request.env['HTTP_AUTHORIZATION']), nil, 401
    end

    get :restapi
    assert_response :unauthorized
  end
end
