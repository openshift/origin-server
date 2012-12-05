require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class CloudUserTest < ActiveSupport::TestCase
  
  test "create" do
    login = "user_" + gen_uuid
    orig_cu = CloudUser.new(login: login)
    orig_cu.save
    cu = CloudUser.find(login)
    assert_equal_users(orig_cu, cu)
  end
  
  test "find by uuid" do
    login = "user_" + gen_uuid
    orig_cu = CloudUser.new(login: login)
    orig_cu.save
    cu = CloudUser.find_by_uuid("CloudUser", orig_cu.uuid)
    assert_equal_users(orig_cu, cu)
  end
  
  def assert_equal_users(user1, user2)
    assert_equal(user1.login, user2.login)
    assert_equal(user1.uuid, user2.uuid)
  end

end
