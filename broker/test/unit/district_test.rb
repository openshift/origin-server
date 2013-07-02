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
    assert(District.where(uuid: orig_d.uuid).count == 0)
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
    assert(District.where(uuid: orig_d.uuid).count == 0)
  end
  
  test "reserve district uid" do
    orig_d = get_district_obj
    orig_d.save!
    uid = District.reserve_uid(orig_d.uuid)
    new_d = District.find_by(uuid: orig_d.uuid)
    assert_equal(orig_d.available_uids.length - 1, new_d.available_uids.length)
    assert_equal(orig_d.available_capacity - 1 , new_d.available_capacity)
    assert(!new_d.available_uids.include?(uid))
    
    (1..new_d.available_capacity).each do |i| 
      uid = District.reserve_uid(orig_d.uuid)
    end
    
    uid = District.reserve_uid(orig_d.uuid)
    assert(uid.nil?)
    
    2.times do |i|
      District.unreserve_uid(orig_d.uuid, 1)
      new_d = District.find_by(uuid: orig_d.uuid)
      assert_equal(1, new_d.available_uids.length)
      assert_equal(1, new_d.available_capacity)
      assert(new_d.available_uids.include?(1))
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
    assert(!new_d.available_uids.include?(uid))

    new_d.available_uids.each do |uid| 
      uid = District.reserve_uid(orig_d.uuid, uid)
    end
    uid = District.reserve_uid(orig_d.uuid)
    assert(uid.nil?)
    new_d = District.find_by(uuid: orig_d.uuid)
    assert_equal(0, new_d.available_uids.length)
    assert_equal(0, new_d.available_capacity)
   
    District.unreserve_uid(orig_d.uuid, preferred_uid)
    new_d = District.find_by(uuid: orig_d.uuid)
    assert_equal(1, new_d.available_uids.length)
    assert_equal(1, new_d.available_capacity)
    assert(new_d.available_uids.include?(preferred_uid))
  end
  
  test "reserve given district uid" do
    d = get_district_obj
    d.save!
    d = District.find_by(uuid: d.uuid)
    assert(!d.available_uids.include?(6001))
    available_capacity_before = d.available_capacity
    assert(!d.reserve_given_uid(6001))
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
    new_d = District.create_district("a")
    assert_equal(new_default_gear_size, new_d.gear_size)
    Rails.application.config.openshift[:default_gear_size] = o_default_gear_size
  end
 
=begin
  test "district nodes" do
    orig_d = get_district_obj
    orig_d.save!
    begin
      hostname = `mco ping | xargs | cut -d' ' -f1`
      hostname.chomp!
      orig_d.add_node(hostname)
      new_d = District.find_by(uuid: orig_d.uuid)
      assert(new_d.server_identities_hash[hostname]["active"])
      
      d = District.find_available
      assert_not_nil(d)
      assert(d.available_capacity > 0)
     
      new_d = District.in("server_identities.name" => [hostname]).first 
      assert_equal(new_d.uuid, orig_d.uuid)
      
      exception = nil
      begin  
        new_d.remove_node(hostname)
      rescue Exception => e
        exception = e
      end
      assert(!exception.nil?)

      new_d = District.find_by(uuid: orig_d.uuid)
      assert(new_d.server_identities_hash[hostname]["active"])
  
      new_d.deactivate_node(hostname)
      new_d = District.find_by(uuid: orig_d.uuid)
      assert(!new_d.server_identities_hash[hostname]["active"])

      new_d.activate_node(hostname)
      new_d = District.find_by(uuid: orig_d.uuid)
      assert(new_d.server_identities_hash[hostname]["active"])
      new_d.deactivate_node(hostname)
      new_d = District.find_by(uuid: orig_d.uuid)
      assert(!new_d.server_identities_hash[hostname]["active"])
 
      new_d.remove_node(hostname)
      new_d = District.find_by(uuid: orig_d.uuid)
      assert(!new_d.server_identities_hash[hostname])

      orig_d.destroy
      assert(District.where(uuid: orig_d.uuid).count == 0)
    ensure
      District.delete_all
      system("rm -f /var/lib/openshift/.settings/district.info")
    end
  end
=end

  def teardown
    District.delete_all
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
    district.active_server_identities_size = 0
    district
  end
end
