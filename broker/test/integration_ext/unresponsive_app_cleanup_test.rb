ENV["TEST_NAME"] = "integration_unresponsive_app_cleanup_test"
require 'test_helper'

class UnresponsiveAppCleanupTest < ActionDispatch::IntegrationTest

  def setup
    @login = "user_" + gen_uuid
    @namespace = "ns" + gen_uuid[0..9]
    @appname = "app" + gen_uuid[0..9]
    @unresponsive_server = "ip-11-10-9-8"

    cu = CloudUser.new(login: @login)
    cu.capabilities['max_gears'] = 30
    cu.save!
    Lock.create_lock(cu)

    @domain = Domain.new(namespace: @namespace, owner: cu)
    @domain.save!
    @districts_enabled = Rails.configuration.msg_broker[:districts][:enabled]
    Rails.configuration.msg_broker[:districts][:enabled] = false 
  end

  def teardown
    # delete the application 
    Application.where(domain: @domain, name: @appname).delete

    # delete the domain
    Domain.where(canonical_namespace: @namespace).delete 

    # delete the user
    CloudUser.where(_id: @user_id).delete

    # delete the usage records
    UsageRecord.where(user_id: @user_id).delete
    Usage.where(user_id: @user_id).delete
  end

  def test_unscalable_app_down
    app = Application.create_app(@appname, ['php-5.3'], @domain)
    gear = app.group_instances[0].gears[0]
    gear.server_identity = @unresponsive_server
    gear.save!
    
    repair_unresponsive_apps

    app = Application.find_by(name: @appname, domain: @domain)
    assert(nil == app)
    assert_equal(2, UsageRecord.where(gear_id: gear._id).count)
    assert_equal(1, Usage.where(gear_id: gear._id).count)
    usage = Usage.find_by(gear_id: gear._id)
    assert(usage.begin_time != nil)
    assert(usage.end_time != nil)
  end

  def repair_unresponsive_apps
    output = `export RAILS_ENV=test; oo-admin-repair --unresponsive-apps --confirm --verbose 2>&1`
    exit_code = $?.exitstatus
    puts output
    puts output if exit_code != 0
    assert_equal(0, exit_code)
  end

end
