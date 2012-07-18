require File.expand_path('../../test_helper', __FILE__)
require 'mocha'

class BuildingControllerTest < ActionController::TestCase

  uses_http_mock

  def json_header(is_post=false)
    {(is_post ? 'Content-Type' : 'Accept') => 'application/json'}.merge!(auth_headers)
  end

  def domain
    {:id => 'test'}
  end
  def app_without_builds
    {:name => 'test', :framework => 'php-5.3'}
  end
  def app_with_builds
    {:name => 'test', :framework => 'php-5.3', :embedded => {'jenkins-client-1.4' => {:info => 'Job URL: http://foo/builds'}}}
  end
  def jenkins_app
    {:name => 'jenkins', :framework => 'jenkins-1.4'}
  end

  def with_app(other_app=nil, app=app_without_builds)
    with_unique_user

    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.get '/broker/rest/cartridges.json', json_header, [].to_json
      mock.get '/broker/rest/domains.json', json_header, [domain].to_json
      mock.get '/broker/rest/domains/test/applications/test.json', json_header, app.to_json
      mock.get '/broker/rest/domains/test/applications.json', json_header, [app, other_app].compact.to_json
      mock.get '/broker/rest/domains/test/applications/test/gear_groups.json', json_header, [
        {:name => '@@app/comp-web/php-5.3', :gears => [
          {:id => 1, :state => 'started'}
        ], :cartridges => [
          {:name => 'php-5.3'},
        ]},
        {:name => '@@app/comp-proxy/php-5.3', :gears => [
          {:id => 2, :state => 'started'},
        ], :cartridges => [
          {:name => 'php-5.3'},
          {:name => 'haproxy-1.4'},
        ]},
        {:name => '@@app/comp-mysql/mysql-5.0', :gears => [
          {:id => 3, :state => 'started'},
        ], :cartridges => [
          {:name => 'my-sql-5.0'},
        ]},
      ].to_json
    end
    {:application_id => 'test'}
  end

  def with_jenkins_and_app
    with_unique_user
    with_app(jenkins_app)
  end

  def with_builds
    with_unique_user
    with_app(jenkins_app, app_with_builds)
  end

  test "should get redirected from show without jenkins client" do
    get :show, with_app
    assert app = assigns(:application)
    assert assigns(:domain)
    assert_redirected_to new_application_building_path(app)
  end

  test "should get redirected from delete without jenkins client" do
    get :delete, with_app
    assert app = assigns(:application)
    assert assigns(:domain)
    assert_redirected_to new_application_building_path(app)
  end

  test "should see new page without a jenkins app" do
    get :new, with_app
    assert app = assigns(:application)
    assert assigns(:domain)
    assert jenk = assigns(:jenkins_server)
    assert !jenk.persisted?
    assert cart = assigns(:cartridge)
    assert !cart.persisted?
    assert_response :success
  end

  test "should see new page and load jenkins app" do
    get :new, with_jenkins_and_app
    assert app = assigns(:application)
    assert assigns(:domain)
    assert jenk = assigns(:jenkins_server)
    assert jenk.persisted?
    assert cart = assigns(:cartridge)
    assert !cart.persisted?
    assert_response :success
  end

  test "should tell the user when the Jenkins app isn't yet registered w/ DNS" do
    # Don't actually sleep for 10 seconds at a go within this test.
    BuildingController.any_instance.expects(:sleep).at_least_once

    # Set up the cartridge save attempt to fail
    Cartridge.any_instance.expects(:save).at_least_once.returns(false)
    Cartridge.any_instance.expects(:has_exit_code?).at_least_once.returns(true)

    # Build the REST environment
    app_args = with_app(jenkins_app, app_without_builds)

    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.post '/broker/rest/domains/test/applications/test/cartridges.json', json_header(true), { :name => 'jenkins-client-1.4' }.to_json, 422
    end

    # Simulate the POST
    post :create, app_args

    # Check that the flash text matches our desired message
    assert_match /^The Jenkins server has not yet registered with DNS/, flash[:info_pre]
  end

  test "should show if all components exist" do
    get :show, with_builds
    assert app = assigns(:application)
    assert app.builds?, app.embedded.jenkins_build_url
    assert app.embedded.jenkins_build_url
    assert assigns(:domain)
    assert_response :success
  end
end
