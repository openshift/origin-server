require File.expand_path('../../../test_helper', __FILE__)

module AdminConsole
  class IndexControllerTest < ActionController::TestCase
    def setup
      Rails.application.config.admin_console[:stats][:cache_timeout] = 0
    end

    def teardown
      Rails.application.config.admin_console[:stats][:read_file] = nil
    end

    test "should get index" do
      get :index
      assert_response :success
    end

    test "should get one profile with an empty district and node" do
      Rails.application.config.admin_console[:stats][:read_file] = "#{ActiveSupport::TestCase.fixture_path}admin_console/empty_district_and_node.json"
      get :index
      assert assigns(:summary_for_profile)
      assert assigns(:summary_for_profile)["small"].present?
      assert_response :success
    end

    test "should get one profile with an overactive node" do
      Rails.application.config.admin_console[:stats][:read_file] = "#{ActiveSupport::TestCase.fixture_path}admin_console/overactive_node.json"
      get :index
      assert assigns(:summary_for_profile)
      assert assigns(:summary_for_profile)["small"].present?
      assert_response :success
      assert_select '.nodes .progress .bar-warning'
    end

    test "should get one profile with an empty node and no districts" do
      Rails.application.config.admin_console[:stats][:read_file] = "#{ActiveSupport::TestCase.fixture_path}admin_console/empty_node_only.json"
      get :index
      assert assigns(:summary_for_profile)
      assert assigns(:summary_for_profile)["small"].present?
      assert_response :success
    end    
  
  end
end
