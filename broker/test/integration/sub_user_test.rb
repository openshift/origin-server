require 'test_helper'

class SubUserTest < ActionDispatch::IntegrationTest
  def setup
    @random = rand(1000000)

    @username = "parent#{@random}"
    @headers = {}
    @headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{@username}:password")
    @headers["Accept"] = "application/json"
  end

  def test_normal_auth_success
    get "rest/domains.json", nil, @headers
    assert_equal 200, status
  end

  def test_subaccount_role_failure_parent_user_missing
    @headers["X-Impersonate-User"] = "subuser#{@random}"
    get "rest/domains.json", nil, @headers
    assert_equal 401, status
  end

  def test_subaccount_role_failure
    get "rest/domains.json", nil, @headers
    assert_equal 200, status

    @headers["X-Impersonate-User"] = "subuser#{@random}"
    get "rest/domains.json", nil, @headers
    assert_equal 401, status
  end

  def test_subaccount_role_success
    get "rest/domains.json", nil, @headers
    assert_equal 200, status

    `oo-admin-ctl-user -l #{@username} --allowsubaccounts true`

    @headers["X-Impersonate-User"] = "subuser#{@random}"
    get "rest/domains.json", nil, @headers
    assert_equal 200, status
  end

  def test_access_someone_elses_subaccount
    get "rest/domains.json", nil, @headers
    assert_equal 200, status

    @headers2 = @headers.clone
    @headers2["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{@username}x:password")
    get "rest/domains.json", nil, @headers2
    assert_equal 200, status

    `oo-admin-ctl-user -l #{@username} --allowsubaccounts true`
    `oo-admin-ctl-user -l #{@username}x --allowsubaccounts true`

    @headers["X-Impersonate-User"] = "subuser#{@random}"
    get "rest/domains.json", nil, @headers
    assert_equal 200, status

    @headers2["X-Impersonate-User"] = "subuser#{@random}"
    get "rest/domains.json", nil, @headers2
    assert_equal 401, status
  end

  def test_delete_subaccount
    get "rest/domains.json", nil, @headers
    assert_equal 200, status

    delete "rest/user.json", nil, @headers
    assert_equal 403, status

    `oo-admin-ctl-user -l #{@username} --allowsubaccounts true`

    @headers2 = @headers.clone
    subaccount_user = "subuser#{@random}"
    @headers2["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{subaccount_user}:password")

    @headers["X-Impersonate-User"] = subaccount_user
    get "rest/domains.json", nil, @headers
    assert_equal 200, status

    domain_name = "namespace#{@random}"
    post "rest/domains.json", { :id => domain_name }, @headers2
    assert_equal 201, status

    delete "rest/user.json", nil, @headers2
    assert_equal 422, status

    delete "rest/domains/#{domain_name}.json", nil, @headers2
    assert_equal 204, status

    delete "rest/user.json", nil, @headers2
    assert_equal 204, status
  end

  def test_subaccount_inherit_gear_sizes
    get "rest/domains.json", nil, @headers
    assert_equal 200, status

    `oo-admin-ctl-user -l #{@username} --addgearsize c9`
    `oo-admin-ctl-user -l #{@username} --allowsubaccounts true`
    `oo-admin-ctl-user -l #{@username} --inheritgearsizes true`

    @headers["X-Impersonate-User"] = "subuser#{@random}"
    get "rest/domains.json", nil, @headers
    assert_equal 200, status

    subuser = CloudUser.find_by(login: "subuser#{@random}")
    capabilities = subuser.get_capabilities
    assert_equal 2, capabilities["gear_sizes"].size
    assert_equal ["c9", "small"], capabilities["gear_sizes"].sort

    `oo-admin-ctl-user -l #{@username} --removegearsize c9`

    subuser = CloudUser.find_by(login: "subuser#{@random}")
    capabilities = subuser.get_capabilities
    assert_equal 1, capabilities["gear_sizes"].size
    assert_equal "small", capabilities["gear_sizes"][0]

    `oo-admin-ctl-user -l #{@username} --inheritgearsizes false`

    subuser = CloudUser.find_by(login: "subuser#{@random}")
    capabilities = subuser.get_capabilities
    assert_equal 1, capabilities["gear_sizes"].size
    assert_equal "small", capabilities["gear_sizes"][0]
  end

  def teardown
  end
end

