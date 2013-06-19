require File.expand_path('../../test_helper', __FILE__)

class SingularResourcesIntegrationTest < ActionDispatch::IntegrationTest

  test "get app by singular resource url" do
    app = with_app
    login

    path = console_path
    path += "/" unless path.end_with? "/"
    get path + "application/#{app.name}", nil, user_env
    assert_response :success

    assert_select "h1.name", :text => app.name

  end

end