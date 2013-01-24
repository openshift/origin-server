require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

module Rails
  def self.logger
    l = Mocha::Mock.new("logger")
    l.stubs(:debug)
    l.stubs(:info)
    l.stubs(:add)
    l
  end
end

class CloudUserTest < ActiveSupport::TestCase
  def setup
    #setup test user auth on the mongo db
    system "/usr/bin/mongo localhost/openshift_broker_dev --eval 'db.addUser(\"openshift\", \"mooo\")' 2>&1 > /dev/null"
  end

  test "validation of login" do
    invalid_chars = '"$^<>|%/;:,\*=~'
    invalid_chars.length.times do |i|
      user = CloudUser.new(login: "test#{invalid_chars[i].chr}login")
      assert user.invalid?
      assert !user.errors[:login].empty?
    end
    
    user = CloudUser.new(login: "kraman@redhat.com")
    assert user.valid?
  end
  
  test "validation of ssh key" do
    invalid_chars = '"$^<>|%;:,\*~'
    invalid_chars.length.times do |i|
      user = CloudUser.new(login: "kraman@redhat.com")
      user.add_ssh_key(SshKey.new(name: 'default', content: "ssh#{invalid_chars[i].chr}key"))
      assert user.invalid?
      
      assert !user.errors[:ssh_keys].empty?
    end
    
    user = CloudUser.new(login: "kraman@redhat.com")
    user.add_ssh_key(SshKey.new(name: 'default', content: "ABCdef012+/="))
    assert user.valid?
  end

  test "create a new user" do
    ssh = "AAAAB3NzaC1yc2EAAAABIwAAAQEAvzdpZ/3+PUi3SkYQc3j8v5W8+PUNqWe7p3xd9r1y4j60IIuCS4aaVqorVPhwrOCPD5W70aeLM/B3oO3QaBw0FJYfYBWvX3oi+FjccuzSmMoyaYweXCDWxyPi6arBqpsSf3e8YQTEkL7fwOQdaZWtW7QHkiDCfcB/LIUZCiaArm2taIXPvaoz/hhHnqB2s3W/zVP2Jf5OkQHsVOTxYr/Hb+/gV3Zrjy+tE9+z2ivL+2M0iTIoSVsUcz0d4g4XpgM8eG9boq1YGzeEhHe1BeliHmAByD8PwU74tOpdpzDnuKf8E9Gnwhsp2yqwUUkkBUoVcv1LXtimkEyIl0dSeRRcMw=="
    namespace = "broker.example.com"
    login = "kraman@redhat.com"
    user = CloudUser.new(login: login)
    user.add_ssh_key(SshKey.new(name: 'default', content: ssh))
    
    observer_seq = sequence("observer_seq")
         
    CloudUser.expects(:notify_observers).with(:before_cloud_user_create, user).in_sequence(observer_seq).at_least_once
    CloudUser.expects(:notify_observers).with(:cloud_user_create_success, user).in_sequence(observer_seq).at_least_once
    CloudUser.expects(:notify_observers).with(:after_cloud_user_create, user).in_sequence(observer_seq).at_least_once

    user.expects(:mongoid_save).returns(true)

    user.save
  end
  
  test "create user fails if user already exists" do
    ssh = "AAAAB3NzaC1yc2EAAAABIwAAAQEAvzdpZ/3+PUi3SkYQc3j8v5W8+PUNqWe7p3xd9r1y4j60IIuCS4aaVqorVPhwrOCPD5W70aeLM/B3oO3QaBw0FJYfYBWvX3oi+FjccuzSmMoyaYweXCDWxyPi6arBqpsSf3e8YQTEkL7fwOQdaZWtW7QHkiDCfcB/LIUZCiaArm2taIXPvaoz/hhHnqB2s3W/zVP2Jf5OkQHsVOTxYr/Hb+/gV3Zrjy+tE9+z2ivL+2M0iTIoSVsUcz0d4g4XpgM8eG9boq1YGzeEhHe1BeliHmAByD8PwU74tOpdpzDnuKf8E9Gnwhsp2yqwUUkkBUoVcv1LXtimkEyIl0dSeRRcMw=="
    namespace = "broker.example.com"
    login = "kraman@redhat.com"
    user = CloudUser.new(login: login)
    user.add_ssh_key(SshKey.new(name: 'default', content: ssh))
     
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

  test "user ssh keys" do
    ssh = "AAAAB3NzaC1yc2EAAAABIwAAAQEAvzdpZ/3+PUi3SkYQc3j8v5W8+PUNqWe7p3xd9r1y4j60IIuCS4aaVqorVPhwrOCPD5W70aeLM/B3oO3QaBw0FJYfYBWvX3oi+FjccuzSmMoyaYweXCDWxyPi6arBqpsSf3e8YQTEkL7fwOQdaZWtW7QHkiDCfcB/LIUZCiaArm2taIXPvaoz/hhHnqB2s3W/zVP2Jf5OkQHsVOTxYr/Hb+/gV3Zrjy+tE9+z2ivL+2M0iTIoSVsUcz0d4g4XpgM8eG9boq1YGzeEhHe1BeliHmAByD8PwU74tOpdpzDnuKf8E9Gnwhsp2yqwUUkkBUoVcv1LXtimkEyIl0dSeRRcMw=="
    login = "kraman@redhat.com"

    user = CloudUser.new(login: login)
    user.add_ssh_key(SshKey.new(name: 'default', content: ssh))
    
    user.add_ssh_key(SshKey.new(name: 'keyname', content: 'key'))
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
  end
  
  def teardown
    Mocha::Mockery.instance.stubba.unstub_all
  end
end
