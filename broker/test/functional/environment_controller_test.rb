ENV["TEST_NAME"] = "functional_environment_controller_test"
require 'test_helper'
class EnvironmentControllerTest < ActionController::TestCase

  def setup
    @controller = EnvironmentController.new
    @request.env['HTTP_ACCEPT'] = "application/json"
  end

  test "show" do
    get :show
    assert_response :success
  end

end