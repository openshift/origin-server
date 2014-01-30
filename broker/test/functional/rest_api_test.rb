ENV["TEST_NAME"] = "functional_rest_api_test"
require_relative '../test_helper'
require 'openshift-origin-controller'
require 'helpers/rest/api'
require 'json'

class RestApiTest < ActionDispatch::IntegrationTest
  def setup
    https!
    stubber
  end

  test "rest api" do
    register_user($user, $password) if registration_required?
    REST_CALLS.each do |rest_version|
      rest_version.each do |rest_api|
        #puts
        #puts "#{rest_api.method}  #{rest_api.uri}  #{rest_api.request}"
        response = http_call(rest_api, true)
        #puts "RSP => #{response.class}, #{response.length}, '#{response}'"
        if response.to_s.length != 0
          response_json = JSON.parse(response)
          rest_api.compare(response_json)
        end
      end
    end
  end

  test "rest api accepts content_type api version" do
    get_via_redirect("/broker/rest/api", nil, 'HTTP_ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json;version=1.1') 
    assert_equal 1.1, JSON.parse(response.body.strip)['api_version']
  end
end
