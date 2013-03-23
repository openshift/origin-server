require File.expand_path('../../test_helper', __FILE__)

class AliasesControllerTest < ActionController::TestCase

  test "should show index" do
    get :index, :application_id => with_app.name
    assert_response :success

    assert app = assigns(:application)
    assert_equal with_app.name, app.name
    assert domain = assigns(:domain)
    assert_equal with_app.domain_id, domain.id
  end

end

