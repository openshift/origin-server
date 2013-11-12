require File.expand_path('../../../test_helper', __FILE__)

module AdminConsole
  class ProfilesControllerTest < ActionController::TestCase
    def setup
      Rails.application.config.admin_console[:stats][:cache_timeout] = 0
    end

    def teardown
      Rails.application.config.admin_console[:stats][:read_file] = nil
    end

    test "should get profile with one empty district and node" do
      Rails.application.config.admin_console[:stats][:read_file] = "#{ActiveSupport::TestCase.fixture_path}admin_console/empty_district_and_node.json"
      get :show, :id => "small"
      assert assigns(:profile)
      if Rails.configuration.msg_broker[:districts][:enabled]
        assert assigns(:districts)
        assert !assigns(:show_nodes)
      else
        assert !assigns(:districts)
        assert assigns(:show_nodes)
      end
      assert !assigns(:undistricted_nodes_exist)
      assert_response :success
    end

    test "should get profile with one empty district and node with nodes displayed" do
      Rails.application.config.admin_console[:stats][:read_file] = "#{ActiveSupport::TestCase.fixture_path}admin_console/empty_district_and_node.json"
      get :show_nodes, :id => "small"
      assert assigns(:profile)
      assert assigns(:nodes)
      assert assigns(:show_nodes)
      assert_response :success
    end

    test "should get profile with node over active capacity with nodes displayed" do
      Rails.application.config.admin_console[:stats][:read_file] = "#{ActiveSupport::TestCase.fixture_path}admin_console/overactive_node.json"
      get :show_nodes, :id => "small"
      assert assigns(:profile)
      assert assigns(:nodes)
      assert assigns(:show_nodes)
      assert_response :success
      assert_select '.nodes .progress .bar-warning'
      assert_select '.node .progress .bar-danger'      
    end    

    test "should get profile with no districts and an empty node with nodes displayed" do
      Rails.application.config.admin_console[:stats][:read_file] = "#{ActiveSupport::TestCase.fixture_path}admin_console/empty_node_only.json"
      get :show, :id => "small"
      assert assigns(:profile)
      assert assigns(:nodes)
      assert assigns(:show_nodes)
      assert_response :success
    end

    test "should get profile with both districted and undistricted nodes" do
      Rails.application.config.admin_console[:stats][:read_file] = "#{ActiveSupport::TestCase.fixture_path}admin_console/district_with_node_and_undistricted_node.json"
      get :show, :id => "small"
      assert assigns(:profile)
      if Rails.configuration.msg_broker[:districts][:enabled]
        assert assigns(:districts)
        assert !assigns(:show_nodes)
      else
        assert !assigns(:districts)
        assert assigns(:show_nodes)
      end
      assert assigns(:undistricted_nodes_exist)
      assert_response :success
    end    
    
  end
end
