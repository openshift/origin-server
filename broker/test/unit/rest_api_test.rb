require 'test_helper'
require 'openshift-origin-controller'
require 'helpers/rest/api'
require 'json'
require 'mocha'

class RestApiUnitTest < ActionDispatch::IntegrationTest #ActiveSupport::TestCase
  def setup
    https!
    stubber
  end

  test "rest api" do
    Rails.cache.clear
    Rails.configuration.action_controller.perform_caching = true
    register_user if registration_required?
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

  def teardown
    Mocha::Mockery.instance.stubba.unstub_all
  end
end
