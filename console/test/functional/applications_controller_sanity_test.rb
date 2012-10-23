require File.expand_path('../../test_helper', __FILE__)

class ApplicationsControllerSanityTest < ActionController::TestCase
  tests ApplicationsController

  def get_post_form(name = 'diy-0.1')
    {
      :name => 'test1', 
      :application_type => name,
      :domain_id => uuid.to_s
    }
  end

  test "should create application and domain, and delete app" do
    with_unique_user
    post(:create, {:application => get_post_form})

    assert app = assigns(:application)
    assert app.errors.empty?, app.errors.inspect
    assert domain = assigns(:domain)
    assert_redirected_to get_started_application_path(app, :wizard => true)

    delete :destroy, :id => app.id
    assert_redirected_to applications_path
  end
end
