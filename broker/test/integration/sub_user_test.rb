ENV["TEST_NAME"] = "functional_sub_user_test"
require 'test_helper'

class SubUserTest < ActionDispatch::IntegrationTest
  def setup
    @random = rand(1000000)

    @username = "parent#{@random}"
    @headers = {}
    @headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{@username}:password")
    @headers["Accept"] = "application/json"

    if File.exist?("/etc/openshift/plugins.d/openshift-origin-auth-mongo.conf")
      `oo-register-user -l admin -p admin --username #{@username} --userpass password`
    end
  end

  def test_normal_auth_success
    get "broker/rest/domains.json", nil, @headers
    assert_equal 200, status
  end

  def test_subaccount_role_failure_parent_user_missing
    @headers["X-Impersonate-User"] = "subuser#{@random}"
    get "broker/rest/domains.json", nil, @headers
    assert_equal 401, status
  end

  def test_subaccount_role_failure
    get "broker/rest/domains.json", nil, @headers
    assert_equal 200, status

    @headers["X-Impersonate-User"] = "subuser#{@random}"
    get "broker/rest/domains.json", nil, @headers
    assert_equal 401, status
  end

  def test_subaccount_role_success
    get "broker/rest/domains.json", nil, @headers
    assert_equal 200, status

    u = CloudUser.find_by login: @username
    u.capabilities["subaccounts"] = true
    u.save

    @headers["X-Impersonate-User"] = "subuser#{@random}"
    get "broker/rest/domains.json", nil, @headers
    assert_equal 200, status
  end

  def test_access_someone_elses_subaccount
    get "broker/rest/domains.json", nil, @headers
    assert_equal 200, status

    @headers2 = {}
    @headers2["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{@username}x:password")
    @headers2["Accept"] = "application/json"
    if File.exist?("/etc/openshift/plugins.d/openshift-origin-auth-mongo.conf")
      `oo-register-user -l admin -p admin --username "#{@username}x" --userpass password`
    end

    get "broker/rest/domains.json", nil, @headers2
    assert_equal 200, status

    u = CloudUser.find_by login: @username
    u.capabilities["subaccounts"] = true
    u.save

    u = CloudUser.find_by login: "#{@username}x"
    u.capabilities["subaccounts"] = true
    u.save

    @headers["X-Impersonate-User"] = "subuser#{@random}"
    get "broker/rest/domains.json", nil, @headers
    assert_equal 200, status

    @headers2["X-Impersonate-User"] = "subuser#{@random}"
    get "broker/rest/domains.json", nil, @headers2
    assert_equal 401, status
  end

  def test_delete_subaccount
    get "broker/rest/domains.json", nil, @headers
    assert_equal 200, status

    delete "broker/rest/user.json", nil, @headers
    assert_equal 403, status

    u = CloudUser.find_by login: "#{@username}"
    u.capabilities["subaccounts"] = true
    u.save

    @headers2 = {}
    subaccount_user = "subuser#{@random}"
    @headers2["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{@username}:password")
    @headers2["Accept"] = "application/json"
    @headers2["X-Impersonate-User"] = subaccount_user

    get "broker/rest/domains.json", nil, @headers
    assert_equal 200, status

    domain_name = "namespace#{@random}"
    
    post "broker/rest/domains.json", { :name => domain_name }, @headers2
    assert_equal 201, status

    delete "broker/rest/user.json", nil, @headers2
    assert_equal 422, status

    delete "broker/rest/domains/#{domain_name}.json", nil, @headers2
    assert_equal 200, status

    delete "broker/rest/user.json", nil, @headers2
    assert_equal 200, status
  end

  def test_subaccount_inherit_gear_sizes
    get "broker/rest/domains.json", nil, @headers
    assert_equal 200, status

    u = CloudUser.find_by login: "#{@username}"
    u.capabilities = {"subaccounts"=>true, "gear_sizes"=>Rails.configuration.openshift[:gear_sizes], "max_gears"=>3, "inherit_on_subaccounts"=>["gear_sizes"]}
    u.save

    user = CloudUser.find_by(login: @username)
    assert_equal Rails.configuration.openshift[:gear_sizes].sort, user.capabilities['gear_sizes'].sort

    @headers["X-Impersonate-User"] = "subuser#{@random}"
    get "broker/rest/domains.json", nil, @headers
    assert_equal 200, status

    subuser = CloudUser.find_by(login: "subuser#{@random}")
    capabilities = subuser.capabilities
    assert_equal Rails.configuration.openshift[:gear_sizes].sort, capabilities["gear_sizes"].sort

    u = CloudUser.find_by login: "#{@username}"
    u.capabilities = {"subaccounts"=>true, "gear_sizes"=>Rails.configuration.openshift[:default_gear_capabilities], "max_gears"=>3, "inherit_on_subaccounts"=>["gear_sizes"]}
    u.save

    subuser = CloudUser.find_by(login: "subuser#{@random}")
    capabilities = subuser.capabilities
    assert_equal Rails.configuration.openshift[:default_gear_capabilities].sort, capabilities["gear_sizes"].sort

    u = CloudUser.find_by login: "#{@username}"
    u.capabilities = {"subaccounts"=>true, "gear_sizes"=>Rails.configuration.openshift[:default_gear_capabilities], "max_gears"=>3, "inherit_on_subaccounts"=>[]}
    u.save

    subuser = CloudUser.find_by(login: "subuser#{@random}")
    capabilities = subuser.capabilities
    assert_equal 1, capabilities["gear_sizes"].size
    assert_equal Rails.configuration.openshift[:default_gear_size], capabilities["gear_sizes"][0]
  end

  def teardown
  end
end

