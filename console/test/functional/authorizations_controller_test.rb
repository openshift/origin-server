require File.expand_path('../../test_helper', __FILE__)

class AuthorizationsControllerTest < ActionController::TestCase
  setup{ with_configured_user }

  def any_token
    Authorization.first(:as => @user) || Authorization.create(:note => 'test token', :as => @user)
  end
  def mock_errors
    errors = ActiveModel::Errors.new(nil)
    errors[:base] = 'An unknown error'
    Authorization.any_instance.stubs(:errors).returns(errors)
  end

  test "should create an authorization" do
    assert_difference "Authorization.all(:as => @user).length", 1 do
      post :create, :authorization => {:note => 'test', :scopes => 'read'}
      assert auth = assigns(:authorization)
      assert_redirected_to authorization_path(auth)
    end
  end

  test "should show an error when a create fails" do
    Authorization.any_instance.expects(:save).returns(false)
    mock_errors
    assert_difference "Authorization.all(:as => @user).length", 0 do
      post :create, :authorization => {:note => 'test', :scopes => 'read'}
      assert assigns(:authorization)
      assert_response :success
      assert_template :new
      assert_select ".alert-error", 'An unknown error'
    end
  end

  test "should display an authorization" do
    auth = any_token
    get :show , :id => auth.id

    assert_response :success
    assert_select "pre", auth.token
    assert_select "td[scope='row']", auth.scopes.first
  end

  test "should show an edit authorization form" do
    auth = any_token
    get :edit , :id => auth.id

    assert_response :success
    assert_select "pre", auth.token
    assert_select "textarea[name='authorization[note]']", auth.note
    assert_select "td[scope='row']", auth.scopes.first
  end

  test "should update an authorization" do
    auth = any_token
    put :update , :id => auth.id, :authorization => {:note => 'new note'}

    assert_redirected_to authorization_path(auth)
    updated = Authorization.find auth.id, :as => @user
    assert_equal updated.note, "new note"
  end

  test "should show an error when an update fails" do
    auth = any_token
    
    Authorization.any_instance.expects(:save).returns(false)
    mock_errors

    assert_difference "Authorization.all(:as => @user).length", 0 do
      put :update , :id => auth.id, :authorization => {:note => 'new note'}
      assert assigns(:authorization)
      assert_response :success
      assert_template :edit
      assert_select ".alert-error", 'An unknown error'
    end
  end

  test "should show a new token form" do
    get :new

    assert_response :success
    assert_select "input[type=checkbox][name='authorization[scopes][]'][value=read]"
    assert_select "td[scope='row']", 'Session'
    assert_select "textarea[name='authorization[note]']"
  end
  
  test "should delete a token" do
    auth = any_token
    assert_difference "Authorization.all(:as => @user).length", -1 do
      delete :destroy, :id => auth.id
      assert_redirected_to settings_path
    end
  end

  test "should delete all tokens" do
    auth = any_token
    auth2 = Authorization.create(:as => @user)
    delete :destroy_all
    assert_redirected_to settings_path
    assert Authorization.all(:as => @user).length == 0
  end
end