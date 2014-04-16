ENV["TEST_NAME"] = "functional_quickstarts_controller_test"
require 'test_helper'
class QuickstartsControllerTest < ActionController::TestCase

  def setup
    @controller = QuickstartsController.new
    @request.env['HTTP_ACCEPT'] = "application/json"
  end

  test "quickstarts show and index" do
    get :index , {}
    assert_response :success
    get :show, {"id" => 1}
    assert_response :success
  end

  test "no quickstart id" do
    get :show, {}
    assert_response :not_found
  end
end
