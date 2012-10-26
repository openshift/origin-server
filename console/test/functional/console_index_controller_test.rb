require File.expand_path('../../test_helper', __FILE__)

class ConsoleIndexControllerTest < ActionController::TestCase
  test 'redirect to applications path' do
    with_configured_user
    get :index
    assert_redirected_to applications_path
  end

  test 'render unauthorized' do
    get :unauthorized
    assert_response :success
    assert_template 'console/unauthorized'
  end

  test 'render help' do
    with_configured_user
    get :help
    assert_response :success
    assert_template 'console/help'
  end
end
