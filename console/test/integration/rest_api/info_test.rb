require File.expand_path('../../../test_helper', __FILE__)

class RestApiInfoTest < ActiveSupport::TestCase
  test "retrieve api info" do
    assert info = RestApi::Info.find(:one)
    assert_equal RestApi::API_VERSION.to_s, info.version.to_s
    assert info.supported_api_versions.length.present?
  end
end
