ENV["TEST_NAME"] = "functional_emb_cart_controller_test"
require 'test_helper'
class EmbCartControllerTest < ActionController::TestCase

  def setup
    @controller = allow_multiple_execution(EmbCartController.new)

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @user = CloudUser.new(login: @login)
    @user.add_gear_size("medium")
    @user.private_ssl_certificates = true
    @user.max_untracked_additional_storage = 10
    @user.save
    Lock.create_lock(@user.id)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
    stubber
    @namespace = "ns#{@random}"
    @domain = Domain.new(namespace: @namespace, owner: @user)
    @domain.save
  end

  def with_app(options=nil)
    @app_name = "app#{@random}"
    @app = Application.create_app(@app_name, cartridge_instances_for(:php), @domain, options)
    assert_equal 1, @app.reload.group_instances.length
  end

  def teardown
    @user.force_delete rescue nil
  end

  test "embedded cartridge create show list and destroy by domain and app name" do
    with_app
    name = mysql_version
    post :create, {"name" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :created
    assert_equal 1, @app.reload.group_instances.length

    get :show, {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :show, {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    @request.env['HTTP_ACCEPT'] = 'application/json'
    get :index , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    delete :destroy , {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    assert_equal 1, @app.reload.group_instances.length
    assert_equal 1, @app.component_instances.length
  end

  test "embedded cartridge add with different gear size" do
    with_app
    name = mysql_version
    post :create, {"name" => name, "domain_id" => @domain.namespace, "application_id" => @app.name, "gear_size" => "medium"}
    assert_response :unprocessable_entity
    assert_equal 1, @app.reload.group_instances.length
    json_messages{ |ms| assert ms.any?{ |m| m['text'].include? "Incompatible gear sizes: small and medium for cartridges" }, ms.inspect }
  end

  test "embedded cartridge create with storage" do
    with_app
    name = mysql_version

    post :create, {"name" => name, "domain_id" => @domain.namespace, "application_id" => @app.name, "additional_gear_storage" => '2'}
    assert_response :created

    get :show, {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal 'cartridge', json['type']
    assert_equal [1, 1, 1, 1, 1, 2], json['data'].values_at('scales_from', 'scales_to', 'supported_scales_from', 'supported_scales_to', 'base_gear_storage', 'additional_gear_storage'), json.inspect
    assert json['data']['creation_time']

    delete :destroy , {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
  end

  test "embedded cartridge add where already exists" do
    with_app
    post :create, {"name" => haproxy_version, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :unprocessable_entity
    json_messages{ |ms| assert ms.any?{ |m| m['text'].include? "haproxy-1.4 cannot be added to existing applications. It is automatically added when you create a scaling application." }, ms.inspect }
  end

  test "embedded cartridge create with requirements pulls in req" do
    with_app
    cart = cartridge_instances_for(:phpmyadmin).first
    type = CartridgeType.new(CartridgeType.cartridge_attributes(cart.cartridge))
    j = JSON.parse(type.manifest_text)
    j['Configure-Order'] = [['mysql', 'mariadb'], 'phpmyadmin']
    j['Requires'] = [['mysql', 'mariadb']]
    type.text = j.to_json
    type.save!
    cart = type.cartridge
    name = cart.name

    post :create, {"cartridges" => [{'id' => cart.id}], "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :created, @response.inspect
    assert_equal 1, @app.reload.group_instances.length
    assert db_cart = @app.cartridges.detect{ |i| i.names.include?('mysql') or i.names.include?('mariadb') }
    assert @app.cartridges.detect{ |i| i.names.include?('phpmyadmin') }

    get :show, {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success

    get :index , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success

    # destroying req removes phpmyadmin
    delete :destroy , {"id" => db_cart.name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success

    assert_equal 1, @app.reload.group_instances.length
    assert !@app.cartridges.detect{ |i| i.names.include?('mysql') or i.names.include?('mariadb') }
    assert !@app.cartridges.detect{ |i| i.names.include?('phpmyadmin') }
    assert @app.cartridges.detect{ |i| i.names.include?('php') }
  end

  test "add show and remove downloaded cartridge to application" do
    with_app
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: downloadmock
      Version: '0.1'
      Versions: ['0.1', '0.2']
      Display-Name: Mock Cart
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Source-Url: manifest://test.zip
      Categories:
      - mock
      - service
      MANIFEST

    post :create, {"url" => "manifest://test", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :created
    assert_equal 1, @app.reload.group_instances.length

    get :show, {"id" => "mock-downloadmock-0.1", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal ["mock-downloadmock-0.1", "0.1", "manifest://test"], json['data'].values_at('name', "version", 'url'), json.inspect
    assert_equal [1, 1, 1, 1, 1, 0], json['data'].values_at('scales_from', 'scales_to', 'supported_scales_from', 'supported_scales_to', 'base_gear_storage', 'additional_gear_storage'), json.inspect

    delete :destroy , {"id" => "mock-downloadmock-0.1", "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
  end

  test "add, show, and remove external downloadable cartridge" do
    with_app
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: externalmock
      Source-Url: manifest://test.zip
      Categories:
      - external
      MANIFEST
    @app_name = "app#{@random}"
    post :create, {"url" => "manifest://test", "application_id" => @app._id}
    assert_response :success
    assert app = assigns(:application)
    assert !app.scalable
    assert_equal 2, app.group_instances.length
    assert_equal 2, app.cartridges.length
    assert_equal 1, app.gears.length
    assert cart = app.cartridges.detect{ |c| c.name == 'externalmock-mock-0.1' }
    assert cart.singleton?
    assert cart.is_external?
    assert cart = app.cartridges.detect{ |c| c.name == php_version }
    assert_equal 1, app.group_instances_with_overrides[0].max_gears
    assert_equal 0, app.group_instances_with_overrides[1].max_gears

    get :show, {"id" => "externalmock-mock-0.1", "application_id" => @app._id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal ["externalmock-mock-0.1", "0.1", "manifest://test"], json['data'].values_at('name', "version", 'url'), json.inspect
    assert_equal [0, 0, 1, 1, 1, 0], json['data'].values_at('scales_from', 'scales_to', 'supported_scales_from', 'supported_scales_to', 'base_gear_storage', 'additional_gear_storage'), json.inspect
    assert json['data']['tags'].include?('external')
    assert_equal 'embedded', json['data']['type']

    delete :destroy, {"id" => "externalmock-mock-0.1", "application_id" => @app._id}
    assert_response :success
    app.reload
    assert_equal 1, app.group_instances.length
    assert_equal 1, app.cartridges.length
    assert_equal 1, app.gears.length
  end

  test "embedded cartridge on scalable app create show list and destroy by domain and app name" do
    with_app(:scalable => true)

    name = mysql_version
    post :create, {"name" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert_equal 'cartridge', json['type']
    assert_equal [1, 1, 1, 1, 1, 0], json['data'].values_at('scales_from', 'scales_to', 'supported_scales_from', 'supported_scales_to', 'base_gear_storage', 'additional_gear_storage'), json.inspect

    get :show, {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal 'cartridge', json['type']
    assert_equal [1, 1, 1, 1, 1, 0], json['data'].values_at('scales_from', 'scales_to', 'supported_scales_from', 'supported_scales_to', 'base_gear_storage', 'additional_gear_storage'), json.inspect

    put :update, {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name, "additional_gear_storage" => 3}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal 'cartridge', json['type']
    assert_equal [1, 1, 1, 1, 1, 3], json['data'].values_at('scales_from', 'scales_to', 'supported_scales_from', 'supported_scales_to', 'base_gear_storage', 'additional_gear_storage'), json.inspect

    get :show, {"id" => php_version, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    assert_equal [php_version, 1, -1, 1, -1, 1, 0], JSON.parse(response.body)['data'].values_at('name', 'scales_from', 'scales_to', 'supported_scales_from', 'supported_scales_to', 'base_gear_storage', 'additional_gear_storage'), response.body

    put :update, {"id" => php_version, "domain_id" => @domain.namespace, "application_id" => @app.name, "additional_gear_storage" => 2}
    assert_response :success
    assert_equal [1, -1, 1, -1, 1, 2], JSON.parse(response.body)['data'].values_at('scales_from', 'scales_to', 'supported_scales_from', 'supported_scales_to', 'base_gear_storage', 'additional_gear_storage'), response.body

    get :show, {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
    assert_equal [1, 1, 1, 1, 1, 3], JSON.parse(response.body)['data'].values_at('scales_from', 'scales_to', 'supported_scales_from', 'supported_scales_to', 'base_gear_storage', 'additional_gear_storage'), response.body

    get :index , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success

    delete :destroy , {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :success
  end

  test "embedded cartridge create show list and destroy by app id" do
    with_app
    name = mysql_version
    post :create, {"name" => name, "application_id" => @app.id}
    assert_response :created
    assert_equal 1, @app.reload.group_instances.length

    get :show, {"id" => name, "application_id" => @app.id}
    assert_response :success
    get :index , {"application_id" => @app.id}
    assert_response :success
    delete :destroy , {"id" => name, "application_id" => @app.id}
    assert_response :success
  end

  test "no app name" do
    with_app
    name = mysql_version
    post :create, {"name" => name, "domain_id" => @domain.namespace}
    assert_response :not_found
    get :show, {"id" => name, "domain_id" => @domain.namespace}
    assert_response :not_found
    put :update, {"id" => name, "domain_id" => @domain.namespace, "additional_gear_storage" => 10}
    assert_response :not_found
    get :index , {"id" => name, "domain_id" => @domain.namespace}
    assert_response :not_found
    delete :destroy , {"id" => name, "domain_id" => @domain.namespace}
    assert_response :not_found
  end

  test "no app id" do
    with_app
    name = mysql_version
    post :create, {"name" => name}
    assert_response :not_found
    get :show, {"id" => name}
    assert_response :not_found
    put :update, {"id" => name, "additional_gear_storage" => 10}
    assert_response :not_found
    get :index , {"id" => name}
    assert_response :not_found
    delete :destroy , {"id" => name}
    assert_response :not_found
  end

  test "no domain id" do
    with_app
    name = mysql_version
    post :create, {"name" => name, "application_id" => @app.name}
    assert_response :not_found
    get :show, {"id" => name, "application_id" => @app.name}
    assert_response :not_found
    put :update, {"id" => name, "application_id" => @app.name, "additional_gear_storage" => 10}
    assert_response :not_found
    get :index , {"id" => name, "application_id" => @app.name}
    assert_response :not_found
    delete :destroy , {"id" => name, "application_id" => @app.name}
    assert_response :not_found
  end

  test "no cartridge id by domain and app name" do
    with_app
    post :create, {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :unprocessable_entity
    get :show, {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
    put :update, {"domain_id" => @domain.namespace, "application_id" => @app.name, "additional_gear_storage" => 10}
    assert_response :not_found
    delete :destroy , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
  end

  test "no cartridge id by app id" do
    with_app
    post :create, {"application_id" => @app.id}
    assert_response :unprocessable_entity
    get :show, {"application_id" => @app.id}
    assert_response :not_found
    put :update, {"application_id" => @app.id, "additional_gear_storage" => 10}
    assert_response :not_found
    delete :destroy , {"application_id" => @app.id}
    assert_response :not_found
  end

  test "invalid cartridge id by domain and app name" do
    with_app
    post :create, {"domain_id" => @domain.namespace, "application_id" => @app.name, "name" => "bogus"}
    assert_response :unprocessable_entity
    get :show, {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
    put :update, {"domain_id" => @domain.namespace, "application_id" => @app.name, "additional_gear_storage" => 10}
    assert_response :not_found
    delete :destroy , {"domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :not_found
  end

  test "invalid cartridge id by app id" do
    with_app
    post :create, {"application_id" => @app.id}
    assert_response :unprocessable_entity
    get :show, {"application_id" => @app.id}
    assert_response :not_found
    put :update, {"application_id" => @app.id, "additional_gear_storage" => 10}
    assert_response :not_found
    delete :destroy , {"application_id" => @app.id}
    assert_response :not_found
  end

  test "destroy web_framework cartridge" do
    with_app
    delete :destroy , {"id" => php_version, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :unprocessable_entity
    delete :destroy , {"id" => php_version, "application_id" => @app.id}
    assert_response :unprocessable_entity
  end

  test "get embedded cartridge in all versions" do
    with_app
    name = mysql_version
    post :create, {"name" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"id" => name, "domain_id" => @domain.namespace, "application_id" => @app.name}
      assert_response :ok, "Getting embedded cartridge for version #{version} failed"
    end
    @request.env['HTTP_ACCEPT'] = "application/json"
  end

  test "add downloadable embedded cartridge" do
    with_app

    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Display-Name: Mock Cart
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Source-Url: manifest://test.zip
      Categories:
      - mock
      - embedded
      MANIFEST
    post :create, {"url" => 'manifest://test', "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :created

    # Instance data is accurate on the object
    app = Application.find(@app._id)
    assert_nil app.downloaded_cart_map
    assert instances = app.component_instances
    assert instances.length == 2
    assert instance = instances[1]
    assert_equal 'manifest://test', instance.manifest_url
    type = OpenShift::Cartridge.new.from_descriptor(YAML.load(instance.manifest_text))
    assert_equal instance._id.to_s, type.id
    assert_equal ['embedded', 'mock'], type.categories.sort
    assert_equal 'Mock Cart', type.display_name
    assert instance_cart = instance.cartridge

    assert carts = app.downloaded_cartridges
    assert carts.length == 1
    assert cart = carts[0]
    assert_same instance_cart, cart
    assert_equal ['embedded', 'mock'], type.categories.sort
    assert_equal 'Mock Cart', cart.display_name
    assert_equal "manifest://test", cart.manifest_url

    delete :destroy, {"id" => cart.name, "application_id" => @app.id}
    assert_response :success

    app.reload
    assert_equal 1, app.component_instances.length
    assert app.downloaded_cartridges.empty?
  end

  test "remove legacy downloadable embedded cartridge" do
    with_app

    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Display-Name: Mock Cart
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Source-Url: manifest://test.zip
      Categories:
      - mock
      - embedded
      MANIFEST
    post :create, {"url" => 'manifest://test', "domain_id" => @domain.namespace, "application_id" => @app.name}
    assert_response :created

    app = Application.find(@app._id)

    # reset the application to a pre migration state
    cart = app.downloaded_cartridges.first
    app.downloaded_cart_map = {cart.original_name => CartridgeCache.cartridge_to_data(cart)}
    instance = app.component_instances[0]
    instance.cartridge_id = nil
    instance.manifest_url = nil
    instance.manifest_text = nil
    app.save!

    delete :destroy, {"id" => cart.name, "application_id" => @app.id}
    assert_response :success

    app.reload
    assert_equal 1, app.component_instances.length
    assert app.downloaded_cartridges.empty?
  end

  def test_attempt_to_add_obsolete_cartridge
    with_app
    Rails.cache.clear
    carts = []
    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "redhat"
    cart.name = "emb-cart"
    cart.provides = ["emb"]
    cart.version = "1.0"
    cart.obsolete = true
    cart.categories = ["embedded"]
    carts << cart

    cart = OpenShift::Cartridge.new
    cart.cartridge_vendor = "redhat"
    cart.name = "emb-cart"
    cart.provides = ["emb"]
    cart.version = "1.1"
    cart.categories = ["embedded"]
    carts << cart
    CartridgeCache.stubs(:get_all_cartridges).returns(carts)

    post :create, {"name" => "emb-cart-1.0", "application_id" => @app.id}
    assert_response :unprocessable_entity
  ensure
    Rails.cache.clear
  end
end
