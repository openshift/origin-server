ENV["TEST_NAME"] = "functional_region_test"
require 'test_helper'

class RegionTest < ActiveSupport::TestCase
  def setup
    super
  end

  test "create and find and delete region" do
    region_name = "region_" + gen_uuid
    region1 = Region.create(region_name) 
    cur_region = Region.find_by(name: region_name)
    assert_equal(region1, cur_region)
    cur_region.delete
    assert_equal(false, Region.where(name: region_name).exists?)

    region = Region.create("g1")
    assert_not_nil(region)
    region.destroy
    assert_equal(false, Region.where(name: region.name).exists?)
  end

  test "add and remove zones from region" do
    region_name = "region_" + gen_uuid
    region1 = Region.create(region_name) 
    assert_equal 0, region1.zones.size
    region1.add_zone("z1")
    region = Region.find_by(name: region_name)
    assert_equal 1, region.zones.size

    exception_count = 0
    region.delete rescue exception_count += 1
    assert_equal(1, exception_count)
    region.remove_zone("z1")
    cur_region = Region.find_by(name: region_name)
    assert_equal 0, cur_region.zones.size
    assert_equal(region1, cur_region)

    cur_region.delete
    assert_equal(false, Region.where(name: region_name).exists?)
  end

  test "list regions and zones" do
    region_name1 = "region_" + gen_uuid
    region_name2 = "region_" + gen_uuid
    region1 = Region.create(region_name1) 
    region2 = Region.create(region_name2) 
    region1.add_zone("z1")
    res = Region.list(region1.name)
    assert_not_equal(nil, /#{region1.name}/.match(res))
    assert_not_equal(nil, /z1/.match(res))
    assert_equal(nil, /#{region2.name}/.match(res))
    res = Region.list
    assert_not_equal(nil, /#{region1.name}/.match(res))
    assert_not_equal(nil, /z1/.match(res))
    assert_not_equal(nil, /#{region2.name}/.match(res))
    region1.remove_zone("z1")
    region1.delete
    region2.delete
  end
end
