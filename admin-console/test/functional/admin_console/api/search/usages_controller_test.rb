require File.expand_path('../../../../../test_helper', __FILE__)

module AdminConsole
  module Api
    module Search
      class UsagesControllerTest < ActionController::TestCase
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
            @app_name = "app#{@random}"
            @app = Application.create_app(@app_name, cartridge_instances_for(:php), @domain)
            @app_alias = Alias.new(fqdn: "app#{@random}.foo.bar")
            @app.aliases.push(@app_alias)
            @app.save
          end unless @app
        end

        test "should search usage records by user id" do
          get :index, :user_id => @user.id, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert_equal 1, json["data"].size
          assert_equal @user.id.to_s, json["data"][0]["user_id"]
        end

        test "should search usage records by gear uuid" do
          get :index, :gear_id => @app.gears[0].uuid, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert_equal 1, json["data"].size
          assert_equal @app.gears[0].uuid, json["data"][0]["gear_id"]
        end        

        test "should search usage records by application name" do
          get :index, :app_name => @app.name, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert_equal @app.name, json["data"][0]["app_name"]
        end

        test "should search usage records by application name with regex" do
          get :index, :app_name_regex => "app.*", :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert json["data"][0]["app_name"] =~ /app.*/
        end        

        test "should not search on unsupported keys" do
          get :index, :gear_size => "small", :format => :json
          assert_response :unprocessable_entity
          assert json = JSON.parse(response.body)
          assert json["error"]["message"] =~ /provide a more specific query/
        end
        
        test "should not search on incompatible keys" do
          get :index, :app_name => "test", :app_name_regex => "test", :format => :json
          assert_response :unprocessable_entity
          assert json = JSON.parse(response.body)
          assert json["error"]["message"] =~ /Can not specify both/
        end

      end
    end
  end
end
