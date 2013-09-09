require File.expand_path('../../../test_helper', __FILE__)

module AdminConsole
  class SuggestionsControllerTest < ActionController::TestCase
    def setup
      Rails.application.config.admin_console[:stats][:read_file] = "#{ActiveSupport::TestCase.fixture_path}admin_console/empty_district_and_node.json"
    end

    def teardown
      Rails.application.config.admin_console[:stats][:read_file] = nil
    end

    test "should get index" do
      get :index
      assert_response :success
      assert assigns(:suggestions)
      assert assigns(:suggestions).is_a? Admin::Suggestion::Container
      assert assigns(:stats_created_at)
    end

    test "should generate no suggestions" do
      get :index, tsugs: 0
      assert_equal 0, assigns(:suggestions).size, "no suggestions"
    end

    test "should generate suggestions" do
      get :index, tsugs: 3
      assert_equal 3, assigns(:suggestions).size
    end

  end
end
