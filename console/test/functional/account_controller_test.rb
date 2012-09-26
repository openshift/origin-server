require File.expand_path('../../test_helper', __FILE__)

class AccountControllerTest < ActionController::TestCase

  test "should render dashboard" do
    with_configured_user
    get :show

    assert_response :success
    assert assigns(:user).login.present?
    assert !assigns(:keys).nil?
    assert assigns(:domain).nil?
  end
end
