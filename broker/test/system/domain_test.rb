require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class DomainTest < ActionDispatch::IntegrationTest

  DOMAIN_COLLECTION_URL = "/rest/domains"
  
  def setup
    @random = rand(1000000)
    @login = "user#{@random}"
    @headers = {}
    @headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{@login}:password")
    @headers["HTTP_ACCEPT"] = "application/json"
    
    https!
  end

  def teardown
    # delete the domain
    request_via_redirect(:delete, DOMAIN_COLLECTION_URL + "/ns#{@random}", {:force => true}, @headers)
    request_via_redirect(:delete, DOMAIN_COLLECTION_URL + "/newns#{@random}", {:force => true}, @headers)
  end

  def test_domain_show
    ns = "ns#{@random}"

    # query domain when domain not yet created
    request_via_redirect(:get, DOMAIN_COLLECTION_URL + "/#{ns}", {:nolinks => true}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 127)

    # query domain list when domain not yet created
    request_via_redirect(:get, DOMAIN_COLLECTION_URL, {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"].length, 0)

    # create domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns, :nolinks => true}, @headers)
    assert_response :created

    # test fetching domain by name
    request_via_redirect(:get, DOMAIN_COLLECTION_URL + "/#{ns}", {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], ns)

    # test getting domain list
    request_via_redirect(:get, DOMAIN_COLLECTION_URL, {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"].length, 1)
    assert_equal(body["data"][0]["id"], ns)
  end

  def test_domain_create_validation
    # domain name not specified
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:nolinks => true}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 106)

    # domain name too short
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => "", :nolinks => true}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 106)

    # domain name too long
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => "ns123456789012345", :nolinks => true}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 106)

    # domain name not alphanumeric
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => "domain_#{rand(5)}", :nolinks => true}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 106)

    # domain name not allowed
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => "openshift", :nolinks => true}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 106)
  end

  def test_domain_create
    ns = "ns#{@random}"
    new_ns = "newns#{@random}"

    # domain should get created
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns, :nolinks => true}, @headers)
    assert_response :created

    # domain creation should fail because namespace is not available
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns, :nolinks => true}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 103)

    # domain creation should fail because user already has a domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => new_ns, :nolinks => true}, @headers)
    assert_response :conflict
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 103)
  end

  def test_domain_update_validation
    ns = "ns#{@random}"
    new_ns = "newns#{@random}"

    # user does not have a domain yet
    request_via_redirect(:put, DOMAIN_COLLECTION_URL + "/#{ns}", {:id => new_ns, :nolinks => true}, @headers)
    assert_response :not_found

    # create the initial domain for the user
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns, :nolinks => true}, @headers)
    assert_response :created

    # new domain name not specified
    request_via_redirect(:put, DOMAIN_COLLECTION_URL + "/#{ns}", {}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 106)

    # new domain name too short
    request_via_redirect(:put, DOMAIN_COLLECTION_URL + "/#{ns}", {:id => ""}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 106)

    # new domain name too long
    request_via_redirect(:put, DOMAIN_COLLECTION_URL + "/#{ns}", {:id => "ns123456789012345"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 106)

    # new domain name not alphanumeric
    request_via_redirect(:put, DOMAIN_COLLECTION_URL + "/#{ns}", {:id => "domain_#{rand(5)}"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 106)

    # domain name not allowed
    request_via_redirect(:put, DOMAIN_COLLECTION_URL + "/#{ns}", {:id => "openshift"}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 106)

    # try to update to the domain with the same name
    request_via_redirect(:put, DOMAIN_COLLECTION_URL + "/#{ns}", {:id => ns}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 103)

    # try to update another user's domain
    @new_headers = {}
    @new_headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("new#{@login}:password")
    @new_headers["HTTP_ACCEPT"] = "application/json"
    request_via_redirect(:put, DOMAIN_COLLECTION_URL + "/#{ns}", {:id => new_ns}, @new_headers)
    assert_response :not_found

    # valid domain update case
    request_via_redirect(:put, DOMAIN_COLLECTION_URL + "/#{ns}", {:id => new_ns, :nolinks => true}, @headers)
    assert_response :ok

    # test fetching domain by name
    request_via_redirect(:get, DOMAIN_COLLECTION_URL + "/#{new_ns}", {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], new_ns)
  end

  def test_domain_update_with_application
    ns = "ns#{@random}"
    new_ns = "newns#{@random}"

    # create the domain for the user
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns, :nolinks => true}, @headers)
    assert_response :created

    # create an application under the user's domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL + "/#{ns}/applications", {:name => "app1", :cartridge => "php-5.3", :nolinks => true}, @headers)
    assert_response :created

    # update domain name
    request_via_redirect(:put, DOMAIN_COLLECTION_URL + "/#{ns}", {:id => new_ns, :nolinks => true}, @headers)
    assert_response :ok

    # test fetching domain by name
    request_via_redirect(:get, DOMAIN_COLLECTION_URL + "/#{new_ns}", {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["id"], new_ns)
  end

  def test_domain_delete
    ns = "ns#{@random}"
    new_ns = "newns#{@random}"
    
    # create the domain for the user
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns, :nolinks => true}, @headers)
    assert_response :created

    # delete a non-existant domain
    request_via_redirect(:delete, DOMAIN_COLLECTION_URL + "/#{new_ns}", {}, @headers)
    assert_response :not_found

    # try to delete another user's domain
    @new_headers = {}
    @new_headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("new#{@login}:password")
    @new_headers["HTTP_ACCEPT"] = "application/json"
    request_via_redirect(:delete, DOMAIN_COLLECTION_URL + "/#{ns}", {}, @new_headers)
    assert_response :not_found

    # delete the domain
    request_via_redirect(:delete, DOMAIN_COLLECTION_URL + "/#{ns}", {}, @headers)
    assert_response :no_content

    # query domain after deletion
    request_via_redirect(:get, DOMAIN_COLLECTION_URL + "/#{ns}", {}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 127)

    # recreate the domain with the same namespace - checking namespace availability
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns, :nolinks => true}, @headers)
    assert_response :created
  end
  
  def test_domain_delete_with_application
    ns = "ns#{@random}"
    new_ns = "newns#{@random}"
    
    # create the domain for the user
    request_via_redirect(:post, DOMAIN_COLLECTION_URL, {:id => ns, :nolinks => true}, @headers)
    assert_response :created

    # create an application under the user's domain
    request_via_redirect(:post, DOMAIN_COLLECTION_URL + "/#{ns}/applications", {:name => "app1", :cartridge => "php-5.3", :nolinks => true}, @headers)
    assert_response :created

    # delete the domain without force option
    request_via_redirect(:delete, DOMAIN_COLLECTION_URL + "/#{ns}", {}, @headers)
    assert_response :bad_request
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 128)

    # delete the domain with force option
    request_via_redirect(:delete, DOMAIN_COLLECTION_URL + "/#{ns}", {:force => true}, @headers)
    assert_response :no_content

    # query domain after deletion
    request_via_redirect(:get, DOMAIN_COLLECTION_URL + "/#{ns}", {}, @headers)
    assert_response :not_found
    body = JSON.parse(@response.body)
    assert_equal(body["messages"][0]["exit_code"], 127)
  end

end
