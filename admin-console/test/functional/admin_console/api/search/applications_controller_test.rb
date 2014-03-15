require File.expand_path('../../../../../test_helper', __FILE__)

module AdminConsole
  module Api
    module Search
      class ApplicationsControllerTest < ActionController::TestCase
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

        test "should search applications by id" do
          get :index, :id => @app.id, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert_equal 1, json["data"].size
          assert_equal @app.id.to_s, json["data"][0]["_id"]
        end

        test "should search applications by name" do
          get :index, :name => @app.name, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert_equal @app.name, json["data"][0]["name"]
        end

        test "should search applications by name with regex" do
          get :index, :name_regex => "app.*", :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert json["data"][0]["name"] =~ /app.*/
        end        

        test "should search applications by alias" do
          get :index, :fqdn => "app#{@random}.foo.bar", :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert_equal "app#{@random}.foo.bar", json["data"][0]["aliases"][0]["fqdn"]
        end

        test "should search applications by alias with regex" do
          get :index, :fqdn_regex => ".*foo\\.bar", :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert json["data"][0]["aliases"][0]["fqdn"] =~ /.*foo\.bar/
        end

        test "should search applications by gear uuid" do
          get :index, :gear_uuid => @app.gears[0].uuid, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert_equal 1, json["data"].size
          assert_equal @app.uuid, json["data"][0]["_id"]
        end

        test "should search applications by domain id" do
          get :index, :domain_id => @app.domain_id, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert_equal @app.domain_id.to_s, json["data"][0]["domain_id"]
        end

        test "should search applications by namespace" do
          get :index, :namespace => @namespace, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert_equal @namespace, json["data"][0]["domain_namespace"]
        end

        test "should search applications by namespace with regex" do
          get :index, :namespace_regex => "ns.*", :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert json["data"][0]["domain_namespace"] =~ /ns.*/
        end      

        test "should not search on unsupported keys" do
          get :index, :owner_id => @app.owner_id, :format => :json
          assert_response :unprocessable_entity
          assert json = JSON.parse(response.body)
          assert json["error"]["message"] =~ /provide a more specific query/
        end
        
        test "should not search on incompatible keys" do
          get :index, :name => "test", :name_regex => "test", :format => :json
          assert_response :unprocessable_entity
          assert json = JSON.parse(response.body)
          assert json["error"]["message"] =~ /Can not specify both/

          get :index, :namespace => "test", :namespace_regex => "test", :format => :json
          assert_response :unprocessable_entity
          assert json = JSON.parse(response.body)
          assert json["error"]["message"] =~ /Can not specify both/

          get :index, :fqdn => "test", :fqdn_regex => "test", :format => :json
          assert_response :unprocessable_entity
          assert json = JSON.parse(response.body)
          assert json["error"]["message"] =~ /Can not specify both/
        end

      end
    end
  end
end
