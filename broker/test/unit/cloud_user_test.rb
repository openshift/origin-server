require File.expand_path('../../test_helper', __FILE__)
require 'openshift-origin-controller'
require 'mocha/setup'

class CloudUserTest < ActiveSupport::TestCase
  def setup
    @login = "user" + gen_uuid[0..9]
  end

  test "validation of ssh key" do
    invalid_chars = '"$^<>|%;:,\*~'
    invalid_chars.length.times do |i|
      user = CloudUser.new(login: @login)
      user.add_ssh_key(UserSshKey.new(name: 'default', content: "ssh#{invalid_chars[i].chr}key"))
      assert user.invalid?

      assert !user.errors[:ssh_keys].empty?
    end

    user = CloudUser.new(login: @login)
    user.add_ssh_key(UserSshKey.new(name: 'default', content: "ABCdef012+/="))
    assert user.valid?
  end

  test "create a new user" do
    ssh = "AAAAB3NzaC1yc2EAAAABIwAAAQEAvzdpZ/3+PUi3SkYQc3j8v5W8+PUNqWe7p3xd9r1y4j60IIuCS4aaVqorVPhwrOCPD5W70aeLM/B3oO3QaBw0FJYfYBWvX3oi+FjccuzSmMoyaYweXCDWxyPi6arBqpsSf3e8YQTEkL7fwOQdaZWtW7QHkiDCfcB/LIUZCiaArm2taIXPvaoz/hhHnqB2s3W/zVP2Jf5OkQHsVOTxYr/Hb+/gV3Zrjy+tE9+z2ivL+2M0iTIoSVsUcz0d4g4XpgM8eG9boq1YGzeEhHe1BeliHmAByD8PwU74tOpdpzDnuKf8E9Gnwhsp2yqwUUkkBUoVcv1LXtimkEyIl0dSeRRcMw=="
    user = CloudUser.new(login: @login)
    user.add_ssh_key(UserSshKey.new(name: 'default', content: ssh))
    observer_seq = sequence("observer_seq")

    CloudUser.expects(:notify_observers).with(:before_cloud_user_create, user).in_sequence(observer_seq).at_least_once
    CloudUser.expects(:notify_observers).with(:cloud_user_create_success, user).in_sequence(observer_seq).at_least_once
    CloudUser.expects(:notify_observers).with(:after_cloud_user_create, user).in_sequence(observer_seq).at_least_once

    user.save!

    found_user = CloudUser.find_by(login: @login)
    assert_equal_users(user, found_user)
  end

  test "update cloud user" do
    login = "user_" + gen_uuid
    orig_cu = CloudUser.new(login: login)
    orig_cu.save!

    orig_cu.set(:consumed_gears, 2)

    updated_cu = CloudUser.find_by(login: login)
    assert_equal(orig_cu.consumed_gears, updated_cu.consumed_gears)
  end

  test "cloud user is equivalent" do
    c = CloudUser.new
    assert c._id
    assert !(c === 'a')
    assert !(c === 1)
    assert c === c._id
    assert c === c._id.to_s
    assert c === c
    assert !(c === nil)
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

  test "create user fails if user already exists" do
    ssh = "AAAAB3NzaC1yc2EAAAABIwAAAQEAvzdpZ/3+PUi3SkYQc3j8v5W8+PUNqWe7p3xd9r1y4j60IIuCS4aaVqorVPhwrOCPD5W70aeLM/B3oO3QaBw0FJYfYBWvX3oi+FjccuzSmMoyaYweXCDWxyPi6arBqpsSf3e8YQTEkL7fwOQdaZWtW7QHkiDCfcB/LIUZCiaArm2taIXPvaoz/hhHnqB2s3W/zVP2Jf5OkQHsVOTxYr/Hb+/gV3Zrjy+tE9+z2ivL+2M0iTIoSVsUcz0d4g4XpgM8eG9boq1YGzeEhHe1BeliHmAByD8PwU74tOpdpzDnuKf8E9Gnwhsp2yqwUUkkBUoVcv1LXtimkEyIl0dSeRRcMw=="
    user = CloudUser.new(login: @login)
    user.add_ssh_key(UserSshKey.new(name: 'default', content: ssh))
    observer_seq = sequence("observer_seq")

    CloudUser.expects(:notify_observers).with(:before_cloud_user_create, user).in_sequence(observer_seq).at_least_once
    CloudUser.expects(:notify_observers).with(:cloud_user_create_error, user).in_sequence(observer_seq).at_least_once
    CloudUser.expects(:notify_observers).with(:after_cloud_user_create, user).in_sequence(observer_seq).at_least_once
    user.expects(:mongoid_save).raises(OpenShift::UserException, 'User exists')

    begin
      user.save
    rescue OpenShift::UserException => e
      assert true
    else
      assert false
    end
  end

  test "capabilities proxy" do
    c = CloudUser.new(login: @login)
    c.save

    assert caps = c.capabilities
    assert caps['max_gears']

    assert caps2 = c.capabilities
    assert_not_same caps, caps2

    c.capabilities = nil
    assert_nil c.capabilities
    assert_nil c.capabilities

    a = {}
    c.capabilities = a
    assert caps3 = c.capabilities
    assert_not_same caps, caps3
    assert_not_same caps2, caps3
    assert_not_equal a.object_id, c.capabilities.object_id
    assert a === c.capabilities
  end

  test "inherited capabilities" do
    parent = CloudUser.create(login: "#{@login}_parent") do |u|
      u._capabilities = u.default_capabilities
      u.capabilities['gear_sizes'] = ['foo', 'bar']
      u.capabilities['inherit_on_subaccounts'] = ['gear_sizes']
    end
    c = CloudUser.create(login: @login){ |u| u.parent_user_id = parent._id }

    assert_equal ['foo', 'bar'], c.allowed_gear_sizes
    assert_equal ['foo', 'bar'], c.capabilities['gear_sizes']
    assert_equal ['foo', 'bar'], c.capabilities.to_hash['gear_sizes']
    assert_equal ['foo', 'bar'], c.capabilities.deep_dup['gear_sizes']
    # fails today
    #assert_equal ['foo', 'bar'], JSON.parse(c.capabilities.to_json)['gear_sizes']
  end

  test "user ssh keys" do
    ssh = "AAAAB3NzaC1yc2EAAAABIwAAAQEAvzdpZ/3+PUi3SkYQc3j8v5W8+PUNqWe7p3xd9r1y4j60IIuCS4aaVqorVPhwrOCPD5W70aeLM/B3oO3QaBw0FJYfYBWvX3oi+FjccuzSmMoyaYweXCDWxyPi6arBqpsSf3e8YQTEkL7fwOQdaZWtW7QHkiDCfcB/LIUZCiaArm2taIXPvaoz/hhHnqB2s3W/zVP2Jf5OkQHsVOTxYr/Hb+/gV3Zrjy+tE9+z2ivL+2M0iTIoSVsUcz0d4g4XpgM8eG9boq1YGzeEhHe1BeliHmAByD8PwU74tOpdpzDnuKf8E9Gnwhsp2yqwUUkkBUoVcv1LXtimkEyIl0dSeRRcMw=="
    user = CloudUser.new(login: @login)
    user.add_ssh_key(UserSshKey.new(name: 'default', content: ssh))

    user.add_ssh_key(UserSshKey.new(name: 'keyname', content: 'key'))
    found_key = false
    user.ssh_keys.each do |key|
      if key.name == 'keyname' && key.content == 'key'
        found_key = true
        break
      end
    end
    assert found_key
    user.save!

    user = CloudUser.find_by(login: @login)
    found_key = false
    user.ssh_keys.each do |key|
      if key.name == 'keyname' && key.content == 'key'
        found_key = true
        break
      end
    end
    assert found_key

    user.remove_ssh_key('keyname')

    found_key = false
    user.ssh_keys.each do |key|
      if key.name == 'keyname' && key.content == 'key'
        found_key = true
        break
      end
    end

    assert !found_key

    user = CloudUser.find_by(login: @login)

    # Make sure everything works with a domain
    domain = Domain.new(namespace: user._id.to_s[0..15], owner: user)
    domain.save!

    user.add_ssh_key(UserSshKey.new(name: 'keyname', content: 'key'))
    user = CloudUser.find_by(login: @login)
    found_key = false
    user.ssh_keys.each do |key|
      if key.name == 'keyname' && key.content == 'key'
        found_key = true
        break
      end
    end
    assert found_key

    domain.delete

    user.remove_ssh_key('keyname')

    found_key = false
    user.ssh_keys.each do |key|
      if key.name == 'keyname' && key.content == 'key'
        found_key = true
        break
      end
    end

    assert !found_key

    # Make sure the user is still there
    CloudUser.find_by(login: @login)
  end

  def assert_equal_users(user1, user2)
    assert_equal(user1.login, user2.login)
    assert_equal(user1._id, user2._id)
  end

  def teardown
    user = CloudUser.find_by(login: @login) rescue nil
    user.force_delete if user
    Mocha::Mockery.instance.stubba.unstub_all
  end
end
