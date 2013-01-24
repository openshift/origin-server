require 'test_helper'

class DistrictTest < ActiveSupport::TestCase
  def setup
    super
  end

  test "create and find and delete district" do
    orig_d = get_district_obj
    orig_d.save!
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
      assert_equal(1 , new_d.available_capacity)
      assert(new_d.available_uids.include?(1))
    end  
  end

  test "inc district externally reserved uids size" do
    orig_d = get_district_obj
    orig_d.save!
    District.inc_externally_reserved_uids_size(orig_d.uuid)
    new_d = District.find_by(uuid: orig_d.uuid)
    assert_equal(orig_d.externally_reserved_uids_size + 1, new_d.externally_reserved_uids_size)
  end
  
  test "district capacity" do
    orig_d = get_district_obj
    orig_d.save!
    orig_available_uids_length = orig_d.available_uids.length
    orig_available_capacity = orig_d.available_capacity
    orig_max_capacity = orig_d.max_capacity
    orig_d.add_capacity(2)
    new_d = District.find_by(uuid: orig_d.uuid)
    assert_equal(orig_available_uids_length + 2, new_d.available_uids.length)
    assert_equal(orig_available_capacity + 2, new_d.available_capacity)
    assert_equal(orig_max_capacity + 2, new_d.max_capacity)
    new_d.remove_capacity(2)
    new_d = District.find_by(uuid: orig_d.uuid)
    assert_equal(orig_available_uids_length, new_d.available_uids.length)
    assert_equal(orig_available_capacity, new_d.available_capacity)
    assert_equal(orig_max_capacity, new_d.max_capacity)
  end
  
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

  def teardown
    District.delete_all
  end

  def get_district_obj
    uuid = gen_uuid
    name = "dist_" + uuid
    district = District.new(name: name)
    district.available_uids = [1,2,3,4,5,6,7,8,9,10]
    district.max_uid = 10
    district.available_capacity = 10
    district.max_capacity = 10
    district.externally_reserved_uids_size = 0
    district.gear_size = "small"
    district.uuid = uuid
    district.active_server_identities_size = 0
    district
  end
end
