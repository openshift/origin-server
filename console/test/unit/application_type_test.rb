require File.expand_path('../../test_helper', __FILE__)

class ApplicationTypeTest < ActiveSupport::TestCase

  def test_cartridge_tag_filter
    types = ApplicationType.all
    (cartridges,) = types.partition{|t| t.cartridge?}
    omit("No cartridges have been registered on this server") if cartridges.empty?
    assert_not_equal 0, cartridges.length, "There should be cartridges to test against"
    filtered = ApplicationType.tagged('cartridge')
    assert_not_equal 0, filtered.length, "No cartridges were returned for the special tag 'cartridge'"
    assert_equal cartridges.length, filtered.length, "Incorrect items were returned for the special tag 'cartridge'"
  end

end
