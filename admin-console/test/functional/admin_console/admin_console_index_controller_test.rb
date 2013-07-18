require 'test_helper'

module AdminConsole
  class AdminConsoleIndexControllerTest < ActionController::TestCase
    test "should get index" do
      get :index
      assert_response :success
    end
  
  end
end
