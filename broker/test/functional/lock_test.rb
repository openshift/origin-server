ENV["TEST_NAME"] = "functional_lock_test"
require 'test_helper'

class LockExt < Lock
  def self.lockuser(*args)
    self.lock_user(*args)
  end

  def self.unlockuser(*args)
    self.unlock_user(*args)
  end

  def self.lockapp(*args)
    self.lock_app(*args)
  end

  def self.unlockapp(*args)
    self.unlock_app(*args)
  end
end

class LockTest < ActiveSupport::TestCase

  test "user application lock" do
    login = "user"+gen_uuid
    domain = "dom"+gen_uuid[0..9]
    app1_name = "app"+gen_uuid
    app2_name = "app"+gen_uuid

    user = CloudUser.new(login: login) 
    domain = Domain.new(namespace: domain)
    domain.owner = user
    app1 = Application.new(name: app1_name)
    app1.domain = domain
    app2 = Application.new(name: app2_name)
    app2.domain = domain

    init_lock = LockExt.create_lock(user.id)

    # Basic lock and unlock for application
    assert_equal(LockExt.lockapp(app1), true)
    assert_equal(LockExt.unlockapp(app1), true)
    cur_lock = Lock.find_by(_id: init_lock._id)
    assert_equal(false, cur_lock.locked)
    assert_equal(true, cur_lock.app_ids.empty?) 
    assert_equal(init_lock, cur_lock)

    # Basic lock and unlock for user
    assert_equal(LockExt.lockuser(user.id), true)
    assert_equal(LockExt.unlockuser(user.id), true)
    cur_lock = Lock.find_by(_id: init_lock._id)
    assert_equal(false, cur_lock.locked)
    assert_equal(true, cur_lock.app_ids.empty?) 
    assert_equal(init_lock, cur_lock)

    # Basic lock and unlock for application and user
    assert_equal(LockExt.lockapp(app1), true)
    assert_equal(LockExt.lockuser(user.id, app1.id), true)
    assert_equal(LockExt.unlockuser(user.id, app1.id), true)
    assert_equal(LockExt.unlockapp(app1), true)
    cur_lock = Lock.find_by(_id: init_lock._id)
    assert_equal(false, cur_lock.locked)
    assert_equal(true, cur_lock.app_ids.empty?) 
    assert_equal(init_lock, cur_lock) 

    # Check no 2 threads get same app lock  
    assert_equal(LockExt.lockapp(app1, 2), true)
    assert_equal(LockExt.lockapp(app1), false)
    sleep(3)
    assert_equal(LockExt.lockapp(app1), true)
    assert_equal(LockExt.unlockapp(app1), true)
    cur_lock = Lock.find_by(_id: init_lock._id)
    assert_equal(false, cur_lock.locked)
    assert_equal(true, cur_lock.app_ids.empty?) 
    assert_equal(init_lock, cur_lock)

    # Check no 2 threads get same user lock
    assert_equal(LockExt.lockuser(user.id), true)
    assert_equal(LockExt.lockuser(user.id), false)
    assert_equal(LockExt.unlockuser(user.id), true)
    assert_equal(LockExt.lockuser(user.id, nil, 2), true)
    assert_equal(LockExt.lockuser(user.id), false)
    sleep(3)
    assert_equal(LockExt.lockuser(user.id), true)
    assert_equal(LockExt.unlockuser(user.id), true)
    cur_lock = Lock.find_by(_id: init_lock._id)
    assert_equal(false, cur_lock.locked)
    assert_equal(true, cur_lock.app_ids.empty?) 
    assert_equal(init_lock, cur_lock)

    # Check no 2 apps get same user lock
    assert_equal(LockExt.lockapp(app1), true)
    assert_equal(LockExt.lockapp(app2), true)
    assert_equal(LockExt.lockuser(user.id, app1.id), true)
    assert_equal(LockExt.lockuser(user.id, app2.id), false)
    assert_equal(LockExt.unlockuser(user.id, app1.id), true)
    assert_equal(LockExt.lockuser(user.id, app2.id), true)
    assert_equal(LockExt.unlockuser(user.id, app2.id), true)
    assert_equal(LockExt.unlockuser(user.id, app2.id), false)
    assert_equal(LockExt.unlockapp(app1), true)
    assert_equal(LockExt.unlockapp(app2), true)
    cur_lock = Lock.find_by(_id: init_lock._id)
    assert_equal(false, cur_lock.locked)
    assert_equal(true, cur_lock.app_ids.empty?) 
    assert_equal(init_lock, cur_lock)
  end
end
