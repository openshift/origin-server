require File.expand_path('../../../test_helper', __FILE__)

module AdminConsole
  class UsersControllerTest < ActionController::TestCase
    def setup    
      @random = rand(1000000000)
      @login = "user#{@random}"
      @password = 'password'
      @user = CloudUser.new(login: @login)
      @user.private_ssl_certificates = true
      @user.save
      Lock.create_lock(@user.id)
      register_user(@login, @password)
    end

    def teardown
      begin
        @user.force_delete
      rescue
      end
    end

    test "should show user by login" do
      get :show, :id => @user.login
      assert_response :success
      assert_select 'h1.header', /#{@user.login}/
    end

    test "should show user not found" do
      user_login = "does_not_exist#{@random}"
      get :show, :id => user_login
      assert_not_found_page "User #{user_login} not found"
    end
    
  end
end
