require File.expand_path('../../../../../test_helper', __FILE__)

module AdminConsole
  module Api
    module Search
      class DistrictsControllerTest < ActionController::TestCase
        def setup 
          begin
            @random = rand(1000000000)

            stubber
            @name = "std1#{@random}"
            @district = District.new(name: @name, gear_size: "small")
            @district.save
          end unless @district
        end

        test "should search districts by id" do
          get :index, :id => @district.uuid, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert_equal 1, json["data"].size
          assert_equal @district.uuid.to_s, json["data"][0]["uuid"]
        end  

        test "should search districts by name" do
          get :index, :name => @name, :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert_equal @name, json["data"][0]["name"]
        end

        test "should search districts by name with regex" do
          get :index, :name_regex => "std1.*", :format => :json
          assert_response :success
          assert json = JSON.parse(response.body)
          assert json["data"].size > 0
          assert json["data"][0]["name"] =~ /std1.*/
        end  
        
        test "should not search on incompatible keys" do
          get :index, :name => "test", :name_regex => "test", :format => :json
          assert_response :unprocessable_entity
          assert json = JSON.parse(response.body)
          assert json["error"]["message"] =~ /Can not specify both/
        end

      end
    end
  end
end
