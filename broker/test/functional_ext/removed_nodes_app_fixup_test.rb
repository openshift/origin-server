ENV["TEST_NAME"] = "functional_ext_removed_nodes_app_fixup_test"
require 'test_helper'

class RemovedNodesAppFixupTest < ActionDispatch::IntegrationTest

  def setup
    @login = "user_" + gen_uuid
    @namespace = "ns" + gen_uuid[0..9]
    @unresponsive_server = "ip-11-10-9-8"

    @cu = CloudUser.new(login: @login)
    @cu.max_gears = 1000
    @cu.ha = true
    @cu.save!
    Lock.create_lock(@cu.id)

    @domain = Domain.new(namespace: @namespace, owner: @cu)
    @domain.save!
    Rails.configuration.openshift[:allow_ha_applications] = true
    @appnames = []
    for i in 0..20
      @appnames[i] = "app#{i}" + gen_uuid[0..9]
    end
    @apps = []
    @lost_gears = []
  end

  def teardown
    # Remove gears no longer in database
    @lost_gears.each do |gear_hash|
      gear = gear_hash[:gear]
      gear.server_identity = gear_hash[:server_identity]
      gear.save!
      gear.destroy_gear
    end

    # delete all applications from the database
    @apps.each do |app|
      Application.where(_id: app._id).delete
    end

    # delete the domain
    Domain.where(canonical_namespace: @namespace).delete 

    # delete the user
    CloudUser.where(_id: @user_id).delete

    # delete the usage records
    UsageRecord.where(user_id: @user_id).delete
    Usage.where(user_id: @user_id).delete
  end

  def test_unresponsive_apps
    #test_unscalable_app_down
    @apps[0] = Application.create_app(@appnames[0], cartridge_instances_for(:php), @domain)
    gear = @apps[0].gears[0]
    gear.server_identity = @unresponsive_server
    gear.save!
    gear0 = gear._id

    #test_scalable_app_no_ha_framework_down
    @apps[1] = Application.create_app(@appnames[1], cartridge_instances_for(:php), @domain, :scalable => true)
    gear = @apps[1].gears[0]
    gear.server_identity = @unresponsive_server
    gear.save!
    gear1 = gear._id

    #test_scalable_app_ha_all_frameworks_down
    @apps[2] = Application.create_app(@appnames[2], cartridge_instances_for(:php), @domain, :scalable => true)
    @apps[2].make_ha
    assert_equal(2, @apps[2].group_instances[0].gears.size)
    assert_equal(true, @apps[2].ha)
    @apps[2].group_instances[0].gears.each do |gear|
      gear.server_identity = @unresponsive_server
      gear.save!
    end

    #test_scalable_app_scaled_up_gear_down
    @apps[3] = Application.create_app(@appnames[3], cartridge_instances_for(:php), @domain, :scalable => true)
    @apps[3].scale_by(@apps[3].group_instances[0]._id, 1)
    assert_equal(2, @apps[3].group_instances[0].gears.size)
    gear = @apps[3].group_instances[0].gears[1]
    gear.server_identity = @unresponsive_server
    gear.save!
    gear3 = gear._id

    #test_scalable_app_ha_framework_gear_down
    @apps[4] = Application.create_app(@appnames[4], cartridge_instances_for(:php), @domain, :scalable => true)
    @apps[4].make_ha
    assert_equal(2, @apps[4].group_instances[0].gears.size)
    assert_equal(true, @apps[4].ha)
    gear = @apps[4].group_instances[0].gears[0]
    @lost_gears << {:server_identity => gear.server_identity, :gear => gear}
    gear.server_identity = @unresponsive_server
    gear.save!
    gear4 = gear._id

    #test_scalable_app_ha_framework_gear_down_db_down
    @apps[5] = Application.create_app(@appnames[5], cartridge_instances_for(:php), @domain, :scalable => true)
    @apps[5].make_ha
    assert_equal(2, @apps[5].group_instances[0].gears.size)
    assert_equal(true, @apps[5].ha)
    @apps[5].add_cartridges(cartridge_instances_for(:mysql))
    assert_equal(2, @apps[5].group_instances.size)
    assert_equal(1, @apps[5].group_instances[1].gears.size)
    gear = @apps[5].group_instances[0].gears[0]
    @lost_gears << {:server_identity => gear.server_identity, :gear => gear}
    gear.server_identity = @unresponsive_server
    gear.save!
    gear5_1 = gear._id
    gear = @apps[5].group_instances[1].gears[0]
    gear.server_identity = @unresponsive_server
    gear.save!
    gear5_2 = gear._id

    #test_scalable_app_no_ha_scaled_up_head_gear_down
    @apps[6] = Application.create_app(@appnames[6], cartridge_instances_for(:php), @domain, :scalable => true)
    @apps[6].scale_by(@apps[6].group_instances[0]._id, 1)
    assert_equal(2, @apps[6].gears.size)
    gear = @apps[6].gears[0]
    gear.server_identity = @unresponsive_server
    gear.save!

    #test_scalable_app_no_ha_db_available_head_gear_down
    @apps[7] = Application.create_app(@appnames[7], cartridge_instances_for(:php), @domain, :scalable => true)
    @apps[7].add_cartridges(cartridge_instances_for(:mysql))
    assert_equal(2, @apps[7].group_instances.size)
    assert_equal(1, @apps[7].group_instances[1].gears.size)
    gear = @apps[7].group_instances[0].gears[0]
    gear.server_identity = @unresponsive_server
    gear.save!

    repair_apps

    #test_unscalable_app_down
    assert_equal(0, Application.where(canonical_name: @appnames[0].downcase).count)
    assert_equal(2, UsageRecord.where(gear_id: gear0).count)
    assert_equal(1, Usage.where(gear_id: gear0).count)
    usage = Usage.find_by(gear_id: gear0)
    assert_not_nil usage.begin_time
    assert_not_nil usage.end_time

    #test_scalable_app_no_ha_framework_down
    assert_equal(0, Application.where(canonical_name: @appnames[1].downcase).count)
    assert_equal(2, UsageRecord.where(gear_id: gear1).count)
    assert_equal(1, Usage.where(gear_id: gear1).count)
    usage = Usage.find_by(gear_id: gear1)
    assert_not_nil usage.begin_time
    assert_not_nil usage.end_time

    #test_scalable_app_ha_all_frameworks_down
    assert_equal(0, Application.where(canonical_name: @appnames[2].downcase).count)
    assert_equal(4, UsageRecord.where(user_id: @cu._id, app_name: @appnames[2]).count)
    assert_equal(2, Usage.where(user_id: @cu._id, app_name: @appnames[2]).count)

    #test_scalable_app_scaled_up_gear_down
    assert_equal(1, Application.where(canonical_name: @appnames[3].downcase).count)
    app = Application.find_by(canonical_name: @appnames[3].downcase)
    assert_equal(1, app.group_instances[0].gears.size)
    assert_equal(2, UsageRecord.where(gear_id: gear3).count)
    assert_equal(1, Usage.where(gear_id: gear3).count)
    usage = Usage.find_by(gear_id: gear3)
    assert_not_nil usage.begin_time
    assert_not_nil usage.end_time

    #test_scalable_app_ha_framework_gear_down
    assert_equal(0, Application.where(canonical_name: @appnames[4].downcase).count)
    assert_equal(4, UsageRecord.where(user_id: @cu._id, app_name: @appnames[4]).count)
    assert_equal(2, Usage.where(user_id: @cu._id, app_name: @appnames[4]).count)

    #test_scalable_app_ha_framework_gear_down_db_down
    assert_equal(0, Application.where(canonical_name: @appnames[5].downcase).count)
    assert_equal(6, UsageRecord.where(user_id: @cu._id, app_name: @appnames[5]).count)
    assert_equal(3, Usage.where(user_id: @cu._id, app_name: @appnames[5]).count)

    #test_scalable_app_no_ha_scaled_up_head_gear_down
    assert_equal(0, Application.where(canonical_name: @appnames[6].downcase).count)
    assert_equal(4, UsageRecord.where(user_id: @cu._id, app_name: @appnames[6]).count)
    assert_equal(2, Usage.where(user_id: @cu._id, app_name: @appnames[6]).count)

    #test_scalable_app_no_ha_db_available_head_gear_down
    assert_equal(0, Application.where(canonical_name: @appnames[7].downcase).count)
    assert_equal(4, UsageRecord.where(user_id: @cu._id, app_name: @appnames[7]).count)
    assert_equal(2, Usage.where(user_id: @cu._id, app_name: @appnames[7]).count)
  end

  def repair_apps(confirm=true)
    output = `env "RAILS_ENV=test" oo-admin-repair --removed-nodes --verbose --confirm #{confirm} 2>&1`
    exit_code = $?.exitstatus
    puts output if exit_code != 0
  end

end
