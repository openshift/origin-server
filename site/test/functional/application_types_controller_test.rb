require File.expand_path('../../test_helper', __FILE__)

inline_test(File.expand_path(__FILE__))

class ApplicationTypesControllerTest < ActionController::TestCase
  def test_should_show_index_with_proper_title
    get :index
    assert_response :success
    assert_select 'head title', 'OpenShift by Red Hat'
  end
end
