require File.expand_path('../../../../../test_helper', __FILE__)

module AdminConsole
  module Api
    module Search
      class DomainsControllerTest < ActionController::TestCase
        def setup 
          begin
            @random = rand(1000000000)
            @login = "user#{@random}"
            @password = 'password'
            @user = CloudUser.new(login: @login)
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

        test "should search domains by id" do
          get :index, :id => @domain.id, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert_equal 1, json["data"].size
          assert_equal @domain.id.to_s, json["data"][0]["_id"]
        end

        test "should search domains by owner id" do
          get :index, :owner_id => @user.id, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert_equal @user.id.to_s, json["data"][0]["owner_id"]
        end

        test "should search domains by namespace" do
          get :index, :namespace => @namespace, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert_equal @namespace, json["data"][0]["namespace"]
        end

        test "should search domains by namespace with regex" do
          get :index, :namespace_regex => "ns.*", :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert json["data"][0]["namespace"] =~ /ns.*/
        end      

        test "should not search on unsupported keys" do
          get :index, :canonical_namespace => @namespace, :format => :json
          assert_response :unprocessable_entity
          assert json = JSON.parse(response.body)
          assert json["error"]["message"] =~ /provide a more specific query/
        end
        
        test "should not search on incompatible keys" do
          get :index, :namespace => "test", :namespace_regex => "test", :format => :json
          assert_response :unprocessable_entity
          assert json = JSON.parse(response.body)
          assert json["error"]["message"] =~ /Can not specify both/
        end

      end
    end
  end
end
