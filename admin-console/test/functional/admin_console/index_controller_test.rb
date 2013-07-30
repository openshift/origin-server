require File.expand_path('../../../test_helper', __FILE__)

module AdminConsole
  class IndexControllerTest < ActionController::TestCase
    test "should get index" do
      get :index
      assert_response :success
    end
  
  end
end
