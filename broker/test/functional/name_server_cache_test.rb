ENV["TEST_NAME"] = "functional_name_server_cache_test"
require 'test_helper'

class NameServerCacheTest < ActiveSupport::TestCase

  def setup
    super
  end

  test "get name servers" do
    NameServerCache.get_name_servers
  end

end
