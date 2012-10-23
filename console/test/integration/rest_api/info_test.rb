require File.expand_path('../../../test_helper', __FILE__)

class RestApiInfoTest < ActiveSupport::TestCase
  test "retrieve api info" do
    assert info = RestApi::Info.find(:one)
    assert info.version.to_f >= 1.0
    assert info.supported_api_versions.length.present?
  end
end
