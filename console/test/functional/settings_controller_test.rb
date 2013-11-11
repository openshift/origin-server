require File.expand_path('../../test_helper', __FILE__)

class SettingsControllerTest < ActionController::TestCase

  test "should render settings with no data" do
    with_unique_user
    get :show
    assert_response :success
    assert assigns(:user)
    assert assigns(:keys).empty?
    assert assigns(:authorizations)

    assert_select '#new_key input[value=Save]'
    assert_select '#new_domain input[value=Save]'
  end

  test "should render settings with keys and a domain" do
    with_domain
    Key.create :name => 'a_key', :raw_content => 'ssh-rsa nossh', :as => @user
    Authorization.create :note => 'test authorization', :scope => 'read', :as => @user

    get :show

    assert_response :success
    assert assigns(:user)
    assert assigns(:domains)
    assert assigns(:domains).present?
    assert assigns(:keys)
    assert assigns(:authorizations)

    assert_select 'td > a', @domain.name

    assert_select 'a', 'test authorization'
    assert_select 'td', 'a_key'
  end
end
