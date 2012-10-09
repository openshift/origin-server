require File.expand_path('../../test_helper', __FILE__)

class ConsoleIndexControllerTest < ActionController::TestCase
  test 'redirect to applications path' do
    with_configured_user
    get :index
    assert_redirected_to applications_path
  end
end
