require File.expand_path('../../test_helper', __FILE__)

class SingularResourcesTest < ActionDispatch::IntegrationTest

  test "get app by singular resource url" do
    app = with_app

    get "/application/#{app.name}", nil, {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(app.as.login, app.as.password)}
    assert_response :success

    assert_select "h1.name", :text => app.name

  end

end