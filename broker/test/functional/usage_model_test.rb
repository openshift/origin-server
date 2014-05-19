ENV["TEST_NAME"] = "functional_usage_model_test"
require 'test_helper'

class UsageModelTest < ActiveSupport::TestCase
  def setup
    super
  end

  test "create and find usage event" do
    orig = usage
    ue = Usage.new(user_id: orig.user_id, app_name: orig.app_name, gear_id: orig.gear_id, begin_time: orig.begin_time,
                   end_time: orig.end_time, usage_type: UsageRecord::USAGE_TYPES[:gear_usage], gear_size: orig.gear_size)
    ue._id = orig._id
    ue.save!
    ue = Usage.find(orig._id)
    ue.updated_at = nil
    assert_equal(orig, ue)
  end

  test "delete usage event" do
    ue = usage
    ue.save!
    ue = Usage.find(ue._id)
    assert_not_nil ue
    ue.delete
    assert_raise(Mongoid::Errors::DocumentNotFound) {Usage.find(ue._id)}
  end

  test "find all usage events" do
    ues = []
    2.times do
      ue = usage
      ue.save!
      ues << ue
    end
    new_ues = Usage.find_all
    ues.each {|ue| assert_equal(true, new_ues.include?(ue))}
  end

  test "find all usage events by user" do
    ue = usage
    ue.save!
    ue = Usage.find_by_user(ue.user_id)
    assert_equal(1, ue.length)
  end

  test "find all user usage events since given time" do
    ue1 = usage
    ue1.save!
    ue2 = usage
    ue2.user_id = ue1.user_id
    ue2.begin_time = ue1.begin_time + 100
    ue2.save!
    ue = Usage.find_by_user_after_time(ue1.user_id, ue1.begin_time + 10)
    assert_equal(1, ue.length)
  end

  test "find latest by user gear" do
    ue1 = usage
    ue1.save!
    ue2 = usage
    ue2.user_id = ue1.user_id
    ue2.gear_id = ue1.gear_id
    ue2.begin_time = ue1.begin_time + 1
    ue2.save!
    ue2.reload
    ue = Usage.find_latest_by_user_gear(ue1.user_id, ue1.gear_id, UsageRecord::USAGE_TYPES[:gear_usage])
    assert_equal ue, ue2
  end

  test "find all user usage events given time range" do
    cur_tm = Time.now
    ue1 = usage
    ue1.begin_time = cur_tm - 100
    ue1.end_time = cur_tm - 10
    ue1.save!
    ue2 = usage
    ue2.user_id = ue1.user_id
    ue2.begin_time = cur_tm
    ue2.end_time = cur_tm + 100
    ue2.save!
    ue3 = usage
    ue3.user_id = ue1.user_id
    ue3.begin_time = cur_tm + 200
    ue3.save!
    ue = Usage.find_by_user_time_range(ue1.user_id, cur_tm + 10, cur_tm + 150)
    assert_equal(1, ue.length)
    ue = Usage.find_by_user_time_range(ue1.user_id, cur_tm + 10, cur_tm + 250)
    assert_equal(2, ue.length)
    ue = Usage.find_by_user_time_range(ue1.user_id, cur_tm -20, cur_tm + 10)
    assert_equal(2, ue.length)
  end

  test "find usage by user gear" do
    ue = usage
    ue.save!
    ue1 = Usage.find_by_user_gear(ue.user_id, ue.gear_id)
    assert_not_nil ue1
    ue1 = Usage.find_by_user_gear(ue.user_id, ue.gear_id, ue.begin_time)
    assert_not_nil ue1
  end

  test "find user usage summary" do
    cur_tm = Time.now
    ue1 = usage
    ue1.begin_time = cur_tm + 1
    ue1.end_time = cur_tm + 101
    ue1.save!
    ue2 = usage
    ue2.user_id = ue1.user_id
    ue2.begin_time = cur_tm + 501
    ue2.end_time = cur_tm + 601
    ue2.save!
    expected_res = { Rails.configuration.openshift[:default_gear_size]  => { 'num_gears' => 2, 'consumed_time' => 200 } }
    res = Usage.find_user_summary(ue1.user_id)
    assert_equal(res, expected_res)
  end

  def usage
    obj = Usage.new(user_id: "user#{gen_uuid}", app_name: "app#{gen_uuid}", gear_id: "gear#{gen_uuid}", begin_time: Time.now.utc, end_time: nil, usage_type: UsageRecord::USAGE_TYPES[:gear_usage])
    obj.gear_size = Rails.configuration.openshift[:default_gear_size]
    obj.addtl_fs_gb = 5
    obj
  end
end
