require File.expand_path('../../test_helper', __FILE__)

class BuildingControllerTest < ActionController::TestCase

  uses_http_mock

  def user
    {:id => 'test', :consumed_gears => 3, :max_gears => 16}
  end
  def domain
    {:id => 'test'}
  end
  def app_without_builds
    {:id => 'testid', :name => 'test', :framework => 'php-5.3', :domain_id => 'test'}
  end
  def app_can_build
    {:id => 'testid', :name => 'test', :framework => 'php-5.3', :domain_id => 'test', :building_app => 'jenkins'}
  end
  def app_with_builds
    {:id => 'testid', :name => 'test', :framework => 'php-5.3', :domain_id => 'test', :building_with => 'jenkins-client-1', :build_job_url => 'Job URL: http://foo/builds', :building_app => 'jenkins'}
  end
  def jenkins_app
    {:id => 'jenkinsid', :name => 'jenkins', :framework => 'jenkins-1', :domain_id => 'test'}
  end

  def with_app(other_app=nil, app=app_without_builds)
    with_unique_user

    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.delete '/broker/rest/domain/test/application/test/cartridge/jenkins-client-1.json', json_header, {}.to_json
      mock.delete '/broker/rest/application/testid/cartridge/jenkins-client-1.json', json_header, {}.to_json

      mock.get '/broker/rest/cartridges.json', anonymous_json_header, [
        {:name => 'jenkins-client-1', :tags => ['ci_builder']},
        {:name => 'jenkins-1', :tags => ['ci']},
      ].to_json

      mock.get '/broker/rest/user.json', json_header, user.to_json
      mock.get '/broker/rest/domain/test.json?include=application_info', json_header, domain.to_json

      mock.get '/broker/rest/domain/test/application/test.json', json_header, app.to_json
      mock.get '/broker/rest/application/testid.json', json_header, app.to_json

      mock.get '/broker/rest/domain/test/application/jenkins.json', json_header, other_app.to_json if other_app
      mock.get '/broker/rest/application/jenkinsid.json', json_header, other_app.to_json if other_app

      mock.get '/broker/rest/domain/test/applications.json', json_header, [app, other_app].compact.to_json
      mock.get '/broker/rest/domain/test/application/test/gear_groups.json', json_header, [
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
    {:application_id => 'testid'}
  end

  def with_jenkins_and_app
    with_unique_user
    with_app(jenkins_app, app_can_build)
  end

  def with_builds
    with_unique_user
    with_app(jenkins_app, app_with_builds)
  end

  test "should get redirected from show without jenkins client" do
    get :show, with_app
    assert app = assigns(:application)
    assert_redirected_to new_application_building_path(app)
  end

  test "should get redirected from delete without jenkins client" do
    get :delete, with_app
    assert app = assigns(:application)
    assert_redirected_to new_application_building_path(app)
  end

  test "should destroy" do
    delete :destroy, with_app
    assert app = assigns(:application)
    assert_redirected_to application_path(app)
  end

  test "should redraw if destroy fails" do
    args = with_builds
    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.delete '/broker/rest/application/testid/cartridge/jenkins-client-1.json', json_header, {:messages => [{:text => 'unable to delete'}]}.to_json, 422
    end

    delete :destroy, args
    assert assigns(:application)
    assert_response :success
    assert_template :delete
    assert_select '.alert-error', 'unable to delete'
  end

  test "should see new page without a jenkins app" do
    get :new, with_app
    assert app = assigns(:application)
    assert jenk = assigns(:jenkins_server)
    assert !jenk.persisted?
    assert cart = assigns(:cartridge)
    assert !cart.persisted?
    assert_response :success
  end

  test "should see new page and load jenkins app" do
    get :new, with_jenkins_and_app
    assert app = assigns(:application)
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
    args = with_app(jenkins_app, app_can_build)

    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.post '/broker/rest/application/testid/cartridges.json', json_header(true), { :name => 'jenkins-client-1' }.to_json, 422
    end

    # Simulate the POST
    post :create, args

    # Check that the flash text matches our desired message
    assert_match /^The Jenkins server is not yet registered with DNS/, flash[:info_pre]
  end

  test "should create a jenkins server if it does not exist" do
    args = with_app(nil, app_without_builds)

    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.post '/broker/rest/application/testid/cartridges.json', json_header(true), { :name => 'jenkins-client-1' }.to_json, 201
      mock.post '/broker/rest/domain/test/applications.json', json_header(true), { :name => 'jenkins2', :framework => 'jenkins-1', :messages => [{:severity => 'result', :text => 'App remote message'}] }.to_json, 201
    end

    post :create, args.merge({:application => {:name => 'jenkins2'}})

    assert_redirected_to application_building_path("testid-test")
    assert flash[:info_pre].include? 'App remote message'
  end

  test "should stop if server creation fails" do
    args = with_app(nil, app_without_builds)

    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.post '/broker/rest/domain/test/applications.json', json_header(true), { :name => 'jenkins2', :framework => 'jenkins-1', :messages => [{:field => 'base', :text => 'App remote error'}] }.to_json, 422
    end

    post :create, args.merge({:application => {:name => 'jenkins2'}})

    assert_response :success
    assert_template :new
    assert_select '.alert-error', 'App remote error'
  end

  test "should create a jenkins server and redraw if cart fails" do
    args = with_app(nil, app_without_builds)

    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.post '/broker/rest/application/testid/cartridges.json', json_header(true), { :name => 'jenkins-client-1' }.to_json, 422
      mock.post '/broker/rest/domain/test/applications.json', json_header(true), { :id => 'jenkinsid2', :name => 'jenkins2', :framework => 'jenkins-1', :messages => [{:severity => 'result', :text => 'App remote message'}] }.to_json, 201
    end

    post :create, args.merge({:application => {:name => 'jenkins2', :domain_name => 'test'}})

    body = mock_body_for{ |r| /applications.json/ =~ r.path }
    assert_equal 'jenkins-1', body['cartridge']
    assert_equal 'jenkins2', body['name']

    assert_response :success
    assert_template :new
    assert flash[:info_pre].include? 'App remote message'
  end

  test "should show if all components exist" do
    get :show, with_builds
    assert app = assigns(:application)
    assert app.builds?, app.build_job_url
    assert app.building_with
    assert_response :success
  end
end
