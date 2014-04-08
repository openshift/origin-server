ENV["TEST_NAME"] = "functional_district_test"
require 'test_helper'

class DistrictTest < ActiveSupport::TestCase
  def setup
    super
  end

  def stubber
    container = OpenShift::ApplicationContainerProxy.instance("node_dns")
    OpenShift::ApplicationContainerProxy.stubs(:instance).returns(container)
    container.stubs(:get_capacity).returns(0)
    container.stubs(:get_node_profile).returns(Rails.configuration.openshift[:default_gear_size])
    container.stubs(:set_district)
  end

  test "create and find and delete district" do
    orig_d = get_district_obj
    orig_d.save!
    d = District.find_by(uuid: orig_d.uuid)
    assert_equal(orig_d, d)
    d.destroy
    assert_equal 0, District.where(uuid: orig_d.uuid).count

    Rails.configuration.msg_broker[:districts][:enabled] = false
    exception_count = 0
    district = District::create_district("d1") rescue exception_count += 1
    assert_equal(1, exception_count)
    Rails.configuration.msg_broker[:districts][:enabled] = true
    district = District::create_district("d1")
    assert_not_nil(district)
    district.destroy
    assert_equal 0, District.where(uuid: district.uuid).count
  end

  test "add and remove node from district" do
    orig_d = get_district_obj
    orig_d.save!

    stubber
    orig_d.add_node("abcd")
    orig_d.deactivate_node("abcd")
    orig_d.remove_node("abcd")
    Mocha::Mockery.instance.stubba.unstub_all

    d = District.find_by(uuid: orig_d.uuid)
    assert_equal(orig_d, d)
    d.destroy
    assert_equal 0, District.where(uuid: orig_d.uuid).count
  end

  test "add and remove node from district when region enabled" do
    orig_d = get_district_obj
    orig_d.save!

    stubber
    server, region_name, zone_name = "s1", "g1", "z1"
    exception_count = 0
    orig_d.add_node(server, region_name) rescue exception_count += 1
    orig_region = Region.create(region_name)
    orig_d.add_node(server, region_name, zone_name) rescue exception_count += 1
    orig_region.add_zone(zone_name)
    orig_d.add_node(server, region_name, zone_name)
    assert_equal(2, exception_count)

    exception_count = 0
    cur_region = Region.find_by(name: region_name)
    assert_equal(1, cur_region.zones.size)
    cur_region.remove_zone(zone_name) rescue exception_count += 1
    cur_region.delete rescue exception_count += 1
    assert_equal(2, exception_count)

    cur_d = District.find_by(uuid: orig_d.uuid)
    cur_d.deactivate_node(server)
    cur_d.remove_node(server)
    cur_region.remove_zone(zone_name)
    cur_region.delete
    cur_d.destroy
    assert_equal 0, District.where(uuid: orig_d.uuid).count
    assert_equal 0, Region.where(name: region_name).count
  end

  test "add node and set and unset region" do
    orig_d = get_district_obj
    orig_d.save!

    stubber
    server, region_name, zone_name = "s1", "g1", "z1"
    orig_d.add_node(server)
    exception_count = 0
    orig_d.set_region(server, region_name, zone_name) rescue exception_count += 1
    orig_region = Region.create(region_name)
    orig_d.set_region(server, region_name, zone_name) rescue exception_count += 1
    orig_region.add_zone(zone_name)
    orig_d.set_region(server, region_name, zone_name)
    orig_d.set_region(server, region_name, zone_name) rescue exception_count += 1
    assert_equal(3, exception_count)

    exception_count = 0
    cur_region = Region.find_by(name: region_name)
    assert_equal(1, cur_region.zones.size)
    cur_region.remove_zone(zone_name) rescue exception_count += 1
    cur_region.delete rescue exception_count += 1
    orig_d.unset_region(server)
    orig_d.unset_region(server)
    assert_equal(2, exception_count)

    cur_d = District.find_by(uuid: orig_d.uuid)
    cur_d.deactivate_node(server)
    cur_d.remove_node(server)
    cur_region.remove_zone(zone_name)
    cur_region.delete
    cur_d.destroy
    assert_equal(0, District.where(uuid: orig_d.uuid).count)
    assert_equal(0, Region.where(name: region_name).count)
  end

  test "reserve district uid" do
    orig_d = get_district_obj
    orig_d.save!
    uid = District.reserve_uid(orig_d.uuid)
    new_d = District.find_by(uuid: orig_d.uuid)
    assert_equal(orig_d.available_uids.length - 1, new_d.available_uids.length)
    assert_equal(orig_d.available_capacity - 1 , new_d.available_capacity)
    assert_equal false, new_d.available_uids.include?(uid)

    (1..new_d.available_capacity).each do |i| 
      uid = District.reserve_uid(orig_d.uuid)
    end

    uid = District.reserve_uid(orig_d.uuid)
    assert_equal true, uid.nil?

    2.times do |i|
      District.unreserve_uid(orig_d.uuid, 1)
      new_d = District.find_by(uuid: orig_d.uuid)
      assert_equal(1, new_d.available_uids.length)
      assert_equal(1, new_d.available_capacity)
      assert_equal(true, new_d.available_uids.include?(1))
    end

    d = get_district_obj
    d.save!
    d.available_capacity.times do |i|
      uid = District.reserve_uid(d.uuid)
    end

    uid = District.reserve_uid(d.uuid)
    assert_nil uid
  end

  test "reserve district preferred uid" do
    orig_d = get_district_obj
    orig_d.save!
    preferred_uid = 10
    uid = District.reserve_uid(orig_d.uuid, preferred_uid)
    assert_equal(uid, preferred_uid)
    new_d = District.find_by(uuid: orig_d.uuid)
    assert_equal(orig_d.available_uids.length - 1, new_d.available_uids.length)
    assert_equal(orig_d.available_capacity - 1 , new_d.available_capacity)
    assert_equal(false, new_d.available_uids.include?(uid))

    new_d.available_uids.each do |uid| 
      uid = District.reserve_uid(orig_d.uuid, uid)
    end
    uid = District.reserve_uid(orig_d.uuid)
    assert_equal true, uid.nil?
    new_d = District.find_by(uuid: orig_d.uuid)
    assert_equal(0, new_d.available_uids.length)
    assert_equal(0, new_d.available_capacity)

    District.unreserve_uid(orig_d.uuid, preferred_uid)
    new_d = District.find_by(uuid: orig_d.uuid)
    assert_equal(1, new_d.available_uids.length)
    assert_equal(1, new_d.available_capacity)
    assert_equal(true, new_d.available_uids.include?(preferred_uid))
  end

  test "reserve given district uid" do
    d = get_district_obj
    d.save!
    d = District.find_by(uuid: d.uuid)
    assert_equal(false, d.available_uids.include?(6001))
    available_capacity_before = d.available_capacity
    assert_equal(false, d.reserve_given_uid(6001))
    d = District.find_by(uuid: d.uuid)
    assert_equal(available_capacity_before, d.available_capacity)
  end

  test "district capacity" do
    orig_d = get_district_obj
    orig_d.save!
    orig_available_uids_length = orig_d.available_uids.length
    orig_available_capacity = orig_d.available_capacity
    orig_max_capacity = orig_d.max_capacity
    orig_max_uid = orig_d.max_uid
    orig_available_uids_min = orig_d.available_uids.min
    orig_available_uids_max = orig_d.available_uids.max
    assert(orig_d.available_uids.reduce{|prev,l| break unless l >= prev; l}, "The initial UIDs are not sorted")

    additional_capacity = 50

    # add capacity
    orig_d.add_capacity(additional_capacity)
    new_d = District.find_by(uuid: orig_d.uuid)
    assert_equal(orig_available_uids_length + additional_capacity, new_d.available_uids.length)
    assert_equal(orig_available_capacity + additional_capacity, new_d.available_capacity)
    assert_equal(orig_max_capacity + additional_capacity, new_d.max_capacity)
    assert_equal(orig_max_uid + additional_capacity, new_d.max_uid)
    assert_equal(orig_available_uids_min, new_d.available_uids.min)
    assert_equal(orig_available_uids_max + additional_capacity, new_d.available_uids.max)
    # assert that the available_uids array is not sorted
    assert_nil(new_d.available_uids.reduce{|prev,l| break unless l >= prev; l}, "The UIDs are not randomized")

    # remove capacity
    new_d.remove_capacity(additional_capacity)
    new_d = District.find_by(uuid: orig_d.uuid)
    assert_equal(orig_available_uids_length, new_d.available_uids.length)
    assert_equal(orig_available_capacity, new_d.available_capacity)
    assert_equal(orig_max_capacity, new_d.max_capacity)
    assert_equal(orig_max_uid, new_d.max_uid)
    assert_equal(orig_available_uids_min, new_d.available_uids.min)
    assert_equal(orig_available_uids_max, new_d.available_uids.max)
  end

  test "available uids sorted" do
    uuid = gen_uuid
    name = "dist_" + uuid
    district = District.new(name: name)
    # assert that the available_uids array is not sorted
    assert_nil(district.available_uids.reduce{|prev,l| break unless l >= prev; l}, "The UIDs are not randomized")
  end

  test "district gear_size matches DEFAULT_GEAR_SIZE" do
    o_default_gear_size = Rails.application.config.openshift[:default_gear_size]
    new_default_gear_size = "newsize"
    Rails.application.config.openshift[:default_gear_size] = new_default_gear_size
    new_d = District.create_district("a" + gen_uuid)
    assert_equal(new_default_gear_size, new_d.gear_size)
    Rails.application.config.openshift[:default_gear_size] = o_default_gear_size
  end

  def get_district_obj
    uuid = gen_uuid
    name = "dist_" + uuid
    district = District.new(name: name)
    # let the initial available_uids be sorted
    # this allows to separately test if additional UIDs are randomized 
    district.available_uids = (1..100).to_a
    district.max_uid = district.available_uids.max
    district.available_capacity = district.available_uids.length
    district.max_capacity = district.available_uids.length
    district.gear_size = Rails.configuration.openshift[:default_gear_size]
    district.uuid = uuid
    district.active_servers_size = 0
    district
  end
end
