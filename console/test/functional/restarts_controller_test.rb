require File.expand_path('../../test_helper', __FILE__)

class RestartsControllerTest < ActionController::TestCase
  uses_http_mock :sometimes

  test 'should show the restart page' do
    get :show, :application_id => with_app.to_param

    assert_response :success
  end

  test 'should set the default flash message' do
    app = with_app

    allow_http_mock
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/broker/rest/application/#{app.id}.json", json_header, app.to_json
      mock.post "/broker/rest/application/#{app.id}/events.json", json_header(true) # No messages on restart
    end

    put :update, :application_id => app.to_param

    assert_equal "The application '#{app.name}' has been restarted", flash[:success]
  end

  test 'should set custom flash message if provided' do
    app = with_app

    restart_response = {:messages => [{:text => 'Test message'}]}

    allow_http_mock
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/broker/rest/application/#{app.id}.json", json_header, app.to_json
      mock.post "/broker/rest/application/#{app.id}/events.json", json_header(true), restart_response.to_json
    end

    put :update, :application_id => app.to_param

    assert_equal 'Test message', flash[:success]
  end

  test 'should redirect to the application page' do
    app = with_app
    put :update, :application_id => app.to_param

    assert_redirected_to application_path(app)
  end

  test 'should actually restart the application' do
    app = with_app
    uri = "/broker/rest/application/#{app.id}/events.json"

    allow_http_mock
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/broker/rest/application/#{app.id}.json", json_header, app.to_json
      mock.post uri, json_header(true)
    end

    put :update, :application_id => app.to_param

    expected = ActiveResource::Request.new(:post, uri, {:event => :restart}, json_header(true))
    assert ActiveResource::HttpMock.requests.include?(expected), 'A restart event was not created.'
  end

end
