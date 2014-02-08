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
    assert cart = CartridgeType.active.first
    request_via_redirect(:get, "/broker/rest/cartridge/#{cart._id}", {}, @headers)
    assert_response :ok
    assert (data = JSON.parse(@response.body)["data"]).is_a?(Hash)
    assert_equal cart._id.to_s, data['id']
    assert data['activation_time'].present?
    assert_nil data['requires']

    inactive = CartridgeType.create(CartridgeType.active.first.attributes)
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
  end

end
