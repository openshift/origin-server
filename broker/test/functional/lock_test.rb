ENV["TEST_NAME"] = "functional_lock_test"
require 'test_helper'

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

    init_lock = Lock.create_lock(user)

    # Basic lock and unlock for application
    assert_equal(Lock.lock_application(app1), true)
    assert_equal(Lock.unlock_application(app1), true)
    cur_lock = Lock.find_by(_id: init_lock._id)
    assert_equal(init_lock, cur_lock) 

    # Basic lock and unlock for application and user
    assert_equal(Lock.lock_application(app1), true)
    assert_equal(Lock.lock_user(user, app1), true)
    assert_equal(Lock.unlock_user(user, app1), true)
    assert_equal(Lock.unlock_application(app1), true)
    cur_lock = Lock.find_by(_id: init_lock._id)
    assert_equal(init_lock, cur_lock) 

    # Check no 2 threads get same app lock  
    assert_equal(Lock.lock_application(app1, 2), true)
    assert_equal(Lock.lock_application(app1), false)
    sleep(3)
    assert_equal(Lock.lock_application(app1), true)
    assert_equal(Lock.unlock_application(app1), true)
    cur_lock = Lock.find_by(_id: init_lock._id)
    assert_equal(init_lock, cur_lock)

    # check no 2 apps get same user lock
    assert_equal(Lock.lock_application(app1), true)
    assert_equal(Lock.lock_application(app2), true)
    assert_equal(Lock.lock_user(user, app1), true)
    assert_equal(Lock.lock_user(user, app2), false)
    assert_equal(Lock.unlock_user(user, app1), true)
    assert_equal(Lock.unlock_application(app1), true)
    assert_equal(Lock.unlock_application(app2), true)
    cur_lock = Lock.find_by(_id: init_lock._id)
    assert_equal(init_lock, cur_lock)
  end
end
