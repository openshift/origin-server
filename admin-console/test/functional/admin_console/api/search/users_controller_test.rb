require File.expand_path('../../../../../test_helper', __FILE__)

module AdminConsole
  module Api
    module Search
      class UsersControllerTest < ActionController::TestCase
        def setup 
          begin
            @random = rand(1000000000)
            @login = "user#{@random}"
            @password = 'password'
            @user = CloudUser.new(login: @login, plan_id: "free", usage_account_id: @random)
            @user.private_ssl_certificates = true
            @user.save
            Lock.create_lock(@user.id)
            register_user(@login, @password)

            stubber
            @namespace = "ns#{@random}"
            @domain = Domain.new(namespace: @namespace, owner:@user)
            @domain.save
          end unless @domain
        end

        def teardown
          begin
            @user.force_delete
          rescue
          end
        end

        test "should search users by id" do
          get :index, :id => @user.id, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert_equal 1, json["data"].size
          assert_equal @user.id.to_s, json["data"][0]["_id"]
        end

        test "should search users by plan id" do
          get :index, :plan_id => @user.plan_id, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert_equal @user.plan_id, json["data"][0]["plan_id"]
        end

        test "should search users by usage account id" do
          get :index, :usage_account_id => @user.usage_account_id, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert_equal @user.usage_account_id, json["data"][0]["usage_account_id"]
        end        

        test "should search users by login" do
          get :index, :login => @login, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert_equal @login, json["data"][0]["login"]
        end

        test "should search users by login with regex" do
          get :index, :login_regex => "user.*", :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert json["data"][0]["login"] =~ /user.*/
        end      

        test "should not search on unsupported keys" do
          get :index, :plan_state => "ACTIVE", :format => :json
          assert_response :unprocessable_entity
          assert json = JSON.parse(response.body)
          assert json["error"]["message"] =~ /provide a more specific query/
        end
        
        test "should not search on incompatible keys" do
          get :index, :login => "test", :login_regex => "test", :format => :json
          assert_response :unprocessable_entity
          assert json = JSON.parse(response.body)
          assert json["error"]["message"] =~ /Can not specify both/
        end

      end
    end
  end
end
