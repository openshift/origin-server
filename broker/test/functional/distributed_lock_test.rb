ENV["TEST_NAME"] = "functional_distributed_lock_test"
require 'test_helper'

class DistributedLockTest < ActiveSupport::TestCase
  def setup
    super
  end

  test "distributed lock" do
    dl = OpenShift::DistributedLock
    type = gen_uuid
    assert_equal true, dl.obtain_lock(type, "1")
    assert_equal false, dl.obtain_lock(type, "1")
    assert_equal false, dl.obtain_lock(type, "2")
    dl.release_lock(type, "1")
    assert_equal true, dl.obtain_lock(type, "2")
    assert_equal true, dl.obtain_lock(type, "2", true)
    dl.release_lock(type)
    assert_equal true, dl.obtain_lock(type, "2")
    dl.release_lock(type)
  end
end
