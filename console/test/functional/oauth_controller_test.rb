require File.expand_path('../../test_helper', __FILE__)

class OauthControllerTest < ActionController::TestCase

  test 'should preserve auth params' do
    get :authorize, {:client_id => "X", :redirect_uri => "Y"}
    assert_response :redirect
    assert_redirected_to login_path(:then => '/console/oauth/authorize?client_id=X&redirect_uri=Y')
  end

  test 'should get parameter errors from broker' do
    @user = with_unique_user

    get :authorize
    assert_response :success
    assert_template :error
    assert_select 'h1', /OAuth.*client_id/

    get :authorize, {:client_id => "X"}
    assert_response :success
    assert_template :error
    assert_select 'h1', /OAuth.*redirect_uri/

    get :authorize, {:client_id => "X", :redirect_uri => "Y"}
    assert_response :success
    assert_template :error
    assert_select 'h1', /OAuth.*invalid_client/
  end

end
