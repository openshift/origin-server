ENV["TEST_NAME"] = "functional_api_controller_test"
require 'test_helper'
class ApiControllerTest < ActionController::TestCase
  
  def setup
    @controller = ApiController.new
    @request.env['HTTP_ACCEPT'] = "application/json"
  end
  
  test "show" do
    get :show
    assert_response :success
  end
  
end