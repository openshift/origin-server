require File.expand_path('../../test_helper', __FILE__)

class ConsoleIndexControllerTest < ActionController::TestCase
  test 'redirect to applications path' do
    with_configured_user
    get :index
    assert_redirected_to applications_path
  end

  test 'render not found if domain missing' do
    with_configured_user
    @controller.expects(:index).raises(RestApi::ResourceNotFound.new(Domain.model_name,nil))
    get :index
    assert_response :success
    assert_select 'h1', /Domain does not exist/
  end

  test 'render not found if page missing' do
    with_configured_user
    @controller.expects(:index).raises(ActionController::RoutingError.new({}))
    get :index
    assert_response :success
    assert_select 'h1', /Page not found/
  end
end
