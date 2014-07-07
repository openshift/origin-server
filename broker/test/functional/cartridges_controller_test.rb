ENV["TEST_NAME"] = "functional_cartridges_controller_test"
require_relative '../test_helper'
require 'openshift-origin-controller'
require 'mocha/setup'

class CartridgesControllerTest < ActionDispatch::IntegrationTest

  def setup
    @headers = {}
    @headers["HTTP_ACCEPT"] = "application/json"

    https!
  end

  test "cart list" do
    # setup cache
    Rails.cache.clear
    Rails.configuration.action_controller.perform_caching = true

    # should be a cache miss
    request_via_redirect(:get, "/broker/rest/cartridges/standalone", {}, @headers)
    assert_response :ok
    body1 = JSON.parse(@response.body)
    supported_api_versions = body1['supported_api_versions']
    cart_count1 = body1["data"].length
    assert cart_count1 > 0
    assert body1['data'].all?{ |c| c['type'] == 'standalone' }

    # should be a cache hit
    request_via_redirect(:get, "/broker/rest/cartridges/standalone", {}, @headers)
    assert_response :ok
    body2 = JSON.parse(@response.body)
    cart_count2 = body2["data"].length
    assert cart_count2 > 0

    assert body1 == body2

    supported_api_versions.each do |version|
      @headers["HTTP_ACCEPT"] = "application/xml; version=#{version}"
      request_via_redirect(:get, "/broker/rest/cartridges/standalone", {}, @headers)
      assert_response :ok
    end
    @headers["HTTP_ACCEPT"] = "application/json"
  end

  test "embedded cart list" do
    # setup cache
    Rails.cache.clear
    Rails.configuration.action_controller.perform_caching = true

    # should be a cache miss
    request_via_redirect(:get, "/broker/rest/cartridges/embedded", {}, @headers)
    assert_response :ok
    body1 = JSON.parse(@response.body)
    cart_count1 = body1["data"].length
    assert cart_count1 > 0

    # should be a cache hit
    request_via_redirect(:get, "/broker/rest/cartridges/embedded", {}, @headers)
    assert_response :ok
    body2 = JSON.parse(@response.body)
    cart_count2 = body2["data"].length
    assert cart_count2 > 0
    assert body2['data'].all?{ |c| c['type'] == 'embedded' }

    assert body1 == body2
  end

  test "find cartridge" do
    request_via_redirect(:get, "/broker/rest/cartridges/redhat-#{php_version}", {}, @headers)
    assert_response :ok
    assert (body = JSON.parse(@response.body))["data"].is_a? Array
    assert_equal 1, body["data"].length
    assert_equal "cartridges", body["type"]

    request_via_redirect(:get, "/broker/rest/cartridges/#{php_version}", {}, @headers)
    assert_response :ok
    assert (body = JSON.parse(@response.body))["data"].is_a? Array
    assert_equal "cartridges", body["type"]

    request_via_redirect(:get, "/broker/rest/cartridge/#{php_version}", {}, @headers)
    assert_response :ok
    assert (body = JSON.parse(@response.body))["data"].is_a? Hash
    assert_equal "cartridge", body["type"]
    assert body['data']['id']
    assert_equal php_version, body['data']['name']

    request_via_redirect(:get, "/broker/rest/cartridge/redhat-#{php_version}", {}, @headers)
    assert_response :not_found
    request_via_redirect(:get, "/broker/rest/cartridges/redhat-#{php_version}", {}, @headers)
    assert_response :ok
    assert (data = JSON.parse(@response.body)["data"]).is_a?(Array) && data.length > 0
    request_via_redirect(:get, "/broker/rest/cartridges", {feature: "redhat-#{php_version}" }, @headers)
    assert_response :ok
    assert (data = JSON.parse(@response.body)["data"]).is_a?(Array) && data.length > 0

    request_via_redirect(:get, "/broker/rest/cartridge/redhat-php", {}, @headers)
    assert_response :not_found
    request_via_redirect(:get, "/broker/rest/cartridges/redhat-php", {}, @headers)
    assert_response :ok
    assert (data = JSON.parse(@response.body)["data"]).is_a?(Array) && data.length > 0
    request_via_redirect(:get, "/broker/rest/cartridges", {feature: 'redhat-php'}, @headers)
    assert_response :ok
    assert (data = JSON.parse(@response.body)["data"]).is_a?(Array) && data.length > 0

    request_via_redirect(:get, "/broker/rest/cartridges", {features: 'redhat-php'}, @headers)
    assert_response :ok
    assert (data = JSON.parse(@response.body)["data"]).is_a?(Array) && data.length > 1

    request_via_redirect(:get, "/broker/rest/cartridges", {features: 'php'}, @headers)
    assert_response :ok
    assert (data = JSON.parse(@response.body)["data"]).is_a?(Array) && data.length > 1

    request_via_redirect(:get, "/broker/rest/cartridge/redhat-php", {}, @headers)
    assert_response :not_found
    request_via_redirect(:get, "/broker/rest/cartridges/redhat-php", {}, @headers)
    assert_response :ok
    assert (data = JSON.parse(@response.body)["data"]).is_a?(Array) && data.length > 0
  end

  test 'find cartridge by id' do
    assert cart = CartridgeType.active.provides('php').first
    request_via_redirect(:get, "/broker/rest/cartridge/#{cart._id}", {}, @headers)
    assert_response :ok
    assert (data = JSON.parse(@response.body)["data"]).is_a?(Hash)
    assert_equal cart._id.to_s, data['id']
    assert data['activation_time'].present?
    assert_nil data['requires']

    inactive = CartridgeType.create(cart.attributes)
    assert !inactive.activated?
    request_via_redirect(:get, "/broker/rest/cartridge/#{inactive._id}", {}, @headers)
    assert_response :ok
    assert (data = JSON.parse(@response.body)["data"]).is_a?(Hash)
    assert_equal inactive._id.to_s, data['id']
    assert_nil data['activation_time']
    assert_nil data['requires']
  end

  test 'get cartridge complex requires' do
    mysql_carts = CartridgeType.active.provides('mysql').select{ |c| c.names.include?('mysql') }.sort_by(&OpenShift::Cartridge::NAME_PRECEDENCE_ORDER).map(&:name)
    mariadb_carts = CartridgeType.active.provides('mariadb').select{ |c| c.names.include?('mariadb') }.sort_by(&OpenShift::Cartridge::NAME_PRECEDENCE_ORDER).map(&:name)
    CartridgeType.where(provides: 'phpx').delete
    CartridgeType.update_from(OpenShift::Runtime::Manifest.manifests_from_yaml(<<-BODY.strip_heredoc)).each(&:activate!)
      ---
      Name: phpx
      Version: '5.3'
      Display-Name: PHPX
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Categories:
      - mock
      - web_framework
      Provides:
      - phpy
      Requires:
      -
        - mysql
        - mariadb
      - web_proxy
      BODY
    request_via_redirect(:get, "/broker/rest/cartridges", {}, @headers)
    assert_response :ok
    assert (data = JSON.parse(@response.body)["data"]).is_a?(Array)
    assert cart = data.detect{ |c| c['name'] == 'mock-phpx-5.3' }
    assert_equal [mariadb_carts+mysql_carts, ["web_proxy"]], cart['requires']
  end

  test "get cartridge in all versions" do
    request_via_redirect(:get, "/broker/rest/cartridges/redhat-#{php_version}", {}, @headers)
    assert_response :ok
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @headers["HTTP_ACCEPT"] = "application/json; version=#{version}"
      request_via_redirect(:get, "/broker/rest/cartridges/redhat-#{php_version}", {}, @headers)
      assert_response :ok, "Getting cartridge for version #{version} failed"
    end
    @headers["HTTP_ACCEPT"] = "application/json"
  end

  test "listing carts with valid_gear_sizes configuration" do
    ## create a mock cartridge that does not support a small gear size
    restricted_cart_name = "mock-no-small"
    CartridgeType.where(:name => restricted_cart_name).delete
    restricted_cart = CartridgeType.new(
        :base_name => restricted_cart_name,
        :cartridge_vendor => 'mock',
        :name => restricted_cart_name,
        :text => {'Name' => restricted_cart_name}.to_json,
        :version => '1.0',
        :categories => [ "mock", "web_framework"],
        :manifest_url => "",
        :display_name => restricted_cart_name,
        :description => "This is a test",
        :obsolete => false
        )
    restricted_cart.provides = restricted_cart.names
    assert restricted_cart.activate!

    ## create users with different gear size capabilities
    users = {}
    users["small"] = create_test_user_with_gear_sizes(['small'])
    users["medium"] = create_test_user_with_gear_sizes(['medium'])
    users["all"] = create_test_user_with_gear_sizes(['small', 'medium'])

    ## create auth headers for each corresponding user
    auth_headers = {}
    users.keys.each { |key| auth_headers[key] = create_basic_auth_headers(users[key])}

    # setup cache
    Rails.cache.clear
    Rails.configuration.action_controller.perform_caching = true

    ## test anonymous access returns the new cart (i.e. no filter of carts)
    mock_cart = assert_cart_present_in_index(@headers, restricted_cart_name, true)
    assert(mock_cart["valid_gear_sizes"].is_a? Array)    
    assert(mock_cart["valid_gear_sizes"].include?("medium"))
    assert(!mock_cart["valid_gear_sizes"].include?("small"))

    ## validate user with only small gear capability does not get cart back
    assert_cart_present_in_index(auth_headers["small"], restricted_cart_name, false)

    ## validate user with medium gear capability does get cart back
    assert_cart_present_in_index(auth_headers["medium"], restricted_cart_name, true)

    ## validate user with all gear capabilities [small, medium, large] does get cart back
    assert_cart_present_in_index(auth_headers["all"], restricted_cart_name, true)

    ## add user with small only gear capability to a domain with all gear sizes capability
    random = rand(1000000000)
    namespace = "gearns#{random}"
    domain = Domain.new(namespace: namespace, owner: users["all"], allowed_gear_sizes: ["small", "medium"])
    member = Member.new(_id: users["small"].id, n: users["small"].login)
    domain.add_members([member])
    assert domain.save

    ## validate user with small gear, but domain membership to medium capability can now see cart
    assert_cart_present_in_index(auth_headers["small"], restricted_cart_name, true)

  end

  def assert_cart_present_in_index(auth_headers, cart_name, not_nil)
    request_via_redirect(:get, "/broker/rest/cartridges", {}, auth_headers)
    assert_response :ok
    assert (body = JSON.parse(@response.body))["data"].is_a? Array
    value = nil
    body["data"].each { |cart| value = cart if cart["name"] == cart_name }
    assert_not_nil(value, "User #{auth_headers}") if not_nil
    assert(value == nil, "User #{auth_headers}") unless not_nil
    value
  end

  def create_basic_auth_headers(user)
    basic_headers = {}
    basic_headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{user.login}:password").gsub(/\n/,'')
    basic_headers["HTTP_ACCEPT"] = "application/json"
    basic_headers['REMOTE_USER'] = user.login
    basic_headers
  end

  def create_test_user_with_gear_sizes(gear_sizes)
    random = rand(1000000000)
    login = "gearuser#{random}"
    password = "password"
    user = CloudUser.new(login: login)
    user.private_ssl_certificates = true
    user.capabilities["gear_sizes"] = gear_sizes
    user.save
    Lock.create_lock(user.id)
    namespace = "ns#{random}"
    domain = Domain.new(namespace: namespace, owner:user)
    domain.save
    register_user(login, password)
    user
  end

end
