require 'test_helper'
require 'helpers/rest/api'
require 'json'

class RestApiTest < ActiveSupport::TestCase
  test "rest api" do
    register_user if registration_required?
    REST_CALLS.each do |rest_version|
      rest_version.each do |rest_api|
        puts "#{rest_api.method}  #{rest_api.uri}  #{rest_api.request}"
        response = http_call(rest_api)
        puts "RSP => #{response}"
        if response.to_s.length != 0
          response_json = JSON.parse(response)
          rest_api.compare(response_json)
        end
      end
    end
  end
end
