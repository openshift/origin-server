require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class CloudUserTest < ActiveSupport::TestCase
  
  test "create cloud user" do
    login = "user_" + gen_uuid
    orig_cu = CloudUser.new(login: login)
    orig_cu.save!
    cu = CloudUser.find_by(login: login)
    assert_equal_users(orig_cu, cu)
  end
  
  test "find by id" do
    login = "user_" + gen_uuid
    orig_cu = CloudUser.new(login: login)
    orig_cu.save!
    cu = CloudUser.find(orig_cu._id)
    assert_equal_users(orig_cu, cu)
  end

  test "delete cloud user" do
    login = "user_" + gen_uuid
    orig_cu = CloudUser.new(login: login)
    orig_cu.save!
    orig_cu.delete
    
    cu = nil
    begin
      cu = CloudUser.find_by(login: login)
    rescue Mongoid::Errors::DocumentNotFound
      # do nothing
    end

    assert_equal(nil, cu)
  end
  
  test "update cloud user" do
    login = "user_" + gen_uuid
    orig_cu = CloudUser.new(login: login)
    orig_cu.save!

    orig_cu.set(:consumed_gears, 2)
    
    updated_cu = CloudUser.find_by(login: login)
    assert_equal(orig_cu.consumed_gears, updated_cu.consumed_gears)
  end
  
  test "find all cloud users" do
    part_login = gen_uuid
    ["_user1", "_user2"].each do |username|
      orig_cu = CloudUser.new(login: part_login + username)
      orig_cu.save!
    end
    assert_equal(CloudUser.where(login: /#{part_login}/i).count, 2)
  end
  
  def assert_equal_users(user1, user2)
    assert_equal(user1.login, user2.login)
    assert_equal(user1._id, user2._id)
  end

end
