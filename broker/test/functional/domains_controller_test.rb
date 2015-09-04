ENV["TEST_NAME"] = "functional_domains_controller_test"
require_relative '../test_helper'
class DomainsControllerTest < ActionController::TestCase

  def setup
    @controller = allow_multiple_execution(DomainsController.new)

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @user = CloudUser.new(login: @login)
    @user.private_ssl_certificates = true
    @user.save
    Lock.create_lock(@user.id)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
    stubber
  end

  def teardown
    begin
      @user.force_delete
    rescue
    end
  end

  test "domain create show list and destroy" do
    namespace = "ns#{@random}"
    post :create, {"name" => namespace}
    assert_response :created

    assert domain = assigns(:domain)
    assert_equal 1, domain.members.length
    assert_equal :admin, domain.members.first.role
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"

      get :show, {"name" => namespace}
      assert_response :success
      assert json = JSON.parse(response.body)
      assert_nil json['data']['application_count']
      assert_nil json['data']['gear_counts']
      if version >= 1.6
        assert_equal Array,  json['data']['allowed_gear_sizes'].class
        assert_equal Fixnum, json['data']['available_gears'].class
        assert_equal Fixnum, json['data']['max_storage_per_gear'].class
        assert_equal Hash,   json['data']['usage_rates'].class
        assert link = json['data']['links']['ADD_APPLICATION']
        assert_equal Rails.configuration.openshift[:download_cartridges_enabled], link['optional_params'].one?{ |p| p['name'] == 'cartridges[][url]' }
      end

      @request.env['HTTP_ACCEPT'] = "application/xml; version=#{version}"
      get :show, {"name" => namespace}
      assert_response :success
    end

    @request.env['HTTP_ACCEPT'] = 'application/json'

    get :show, {"name" => namespace, "include" => 'application_info'}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal 0, json['data']['application_count']
    assert (gears = json['data']['gear_counts']).is_a?(Hash)
    assert gears.empty?
    assert_equal Array,  json['data']['allowed_gear_sizes'].class
    assert_equal Fixnum, json['data']['available_gears'].class
    assert_equal Fixnum, json['data']['max_storage_per_gear'].class
    assert_equal Hash,   json['data']['usage_rates'].class

    get :index , {}
    assert_response :success
    new_namespace = "xns#{@random}"
    put :update, {"existing_name" => namespace, "name" => new_namespace}
    assert_response :success
    delete :destroy , {"name" => new_namespace}
    assert_response :ok
  end

  test "domain create with blacklisted name" do
    blacklisted_words = OpenShift::ApplicationContainerProxy.get_blacklisted
    return unless blacklisted_words.present?

    post :create, {"name" => blacklisted_words.first}
    assert_response :forbidden
  end

  test "invalid empty or non-existent domain name" do
    post :create, {}
    assert_response :unprocessable_entity
    get :show, {}
    assert_response :not_found
    new_namespace = "xns#{@random}"
    put :update , {"name" => new_namespace}
    assert_response :not_found
    delete :destroy , {}
    assert_response :not_found

    get :show, {"name" => "bogus"}
    assert_response :not_found
    new_namespace = "xns#{@random}"
    put :update , {"existing_name" => "bogus", "name" => new_namespace}
    assert_response :not_found
    delete :destroy , {"name" => "bogus"}
    assert_response :not_found
    #try name with a "-"
    namespace = "ns-#{@random}"
    post :create, {"name" => namespace}
    assert_response :unprocessable_entity
    #try name with a "."
    namespace = "ns.#{@random}"
    post :create, {"name" => namespace}
    assert_response :unprocessable_entity
    #try name that exists
    namespace = "ns#{@random}"

    CloudUser.any_instance.stubs(:max_domains).returns(2)
    post :create, {"name" => namespace}
    assert_response :created
    post :create, {"name" => namespace}
    assert_response :unprocessable_entity

    post :create, {"name" => " "}
    assert_response :unprocessable_entity

    # update to the same name, must provide at least one change
    put :update , {"existing_name" => namespace, "name" => "ns#{@random}"}
    assert_response :unprocessable_entity

    CloudUser.any_instance.stubs(:max_domains).returns(1)

    #try more than one domain
    namespace = "ns#{@random}X"
    post :create, {"name" => namespace}
    assert_response :conflict
  end

  test "user can create multiple domains" do
    CloudUser.any_instance.stubs(:max_domains).returns(2)

    assert_difference("@user.domains.count", 1) do
      post :create, {"name" => "ns1#{@random}"}
      assert_response :success
    end

    assert_difference("@user.domains.count", 1) do
      post :create, {"name" => "ns2#{@random}"}
      assert_response :success
    end

    assert_difference("@user.domains.count", 0) do
      post :create, {"name" => "ns3#{@random}"}
      assert_response :conflict
    end
  end

  test "delete domain with apps" do
    namespace = "ns#{@random}"
    domain = Domain.new(namespace: namespace, owner:@user)
    domain.save

    app_name = "app#{@random}"
    app = Application.create_app(app_name, cartridge_instances_for(:php), domain)
    app.save

    delete :destroy , {"name" => namespace}
    assert_response :unprocessable_entity

    delete :destroy , {"name" => namespace, "force" => true}
    assert_response :ok
  end

  test "update domain with apps" do
    namespace = "ns#{@random}"
    domain = Domain.new(namespace: namespace, owner:@user)
    domain.save

    app_name = "app#{@random}"
    app = Application.create_app(app_name, cartridge_instances_for(:php), domain)
    app.save

    get :show, {"name" => namespace, "include" => 'application_info'}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal 1, json['data']['application_count']
    assert (gears = json['data']['gear_counts']).is_a?(Hash)
    assert_equal 1, gears['small']


    new_namespace = "xns#{@random}"
    put :update, {"existing_name" => namespace, "name" => new_namespace}
    assert_response :unprocessable_entity

    app.destroy_app

    put :update, {"existing_name" => namespace, "name" => new_namespace}
    assert_response :success
    get :show, {"name" => new_namespace}
    assert_response :success
  end

end
