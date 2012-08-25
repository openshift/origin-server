require File.expand_path('../../test_helper', __FILE__)

class OverridesTest < ActiveSupport::TestCase

  test "rack response override" do
    r = ActionDispatch::Response.new
    assert 'SAMEORIGIN', r.to_a[1]['X-Frame-Options']
  end
end
