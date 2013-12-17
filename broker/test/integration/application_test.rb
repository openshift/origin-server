ENV["TEST_NAME"] = "integration_application_test"
require 'test_helper'

class ApplicationTest < ActiveSupport::TestCase
  include OpenShift

  def setup
    super
  end

  def app_setup
    register_user
    @namespace = "domain" + gen_uuid[0..9]
    user_name = "user" + gen_uuid[0..6]
    @user = CloudUser.new(login: user_name)
    @user.save
    @domain = Domain.new(namespace: @namespace, owner: @user)
    @domain.save
    Lock.create_lock(@user)
    stubber
    OpenShift::ApplicationContainerProxy.unstub(:find_available)
  end

  def district_stubber
    Rails.configuration.msg_broker[:districts][:enabled] = true
    container = OpenShift::ApplicationContainerProxy.instance("node_dns")
    OpenShift::ApplicationContainerProxy.stubs(:instance).returns(container)
    container.stubs(:get_capacity).returns(0)
    container.stubs(:get_node_profile).returns(Rails.configuration.openshift[:default_gear_size])
    container.stubs(:set_district)
  end

  test "create find update delete application" do
    ns = "ns" + gen_uuid[0..12]
    app_name = "app" + gen_uuid[0..12]

    orig_d = Domain.new(namespace: ns)
    orig_d.save!

    orig_app = Application.new(domain: orig_d, name: app_name)
    orig_app.save!

    app = Application.find_by(canonical_name: app_name.downcase)

    assert_equal(app.name, orig_app.name)
    assert_equal(app.domain_namespace, orig_app.domain_namespace)

    app.aliases.push(Alias.new(fqdn: "app.foo.bar"))

    updated_app = Application.find_by(canonical_name: app_name.downcase)
    assert_equal(app.name, orig_app.name)
    assert_equal(app.aliases.length, updated_app.aliases.length)
    assert_equal(app.aliases[0], updated_app.aliases[0])

    app.delete

    deleted_app = nil
    begin
      deleted_app = Application.find_by(canonical_name: app_name.downcase)
    rescue Mongoid::Errors::DocumentNotFound
      # ignore
    end
    assert_equal(deleted_app, nil)
  end

  test "create scalable app and ensure gears belong to single region and different zones" do
    return unless OpenShift.const_defined?('MCollectiveApplicationContainerProxy')
    dist = get_district_obj
    dist.save!

    app_setup
    district_stubber
    # test require region for app create
    OpenShift::MCollectiveApplicationContainerProxy.stubs('rpc_get_fact').multiple_yields(["s00", 100])
    dist.add_node("s00")
    Rails.configuration.msg_broker[:regions][:enabled] = false
    Rails.configuration.msg_broker[:regions][:require_for_app_create] = true
    app_name = "a1"
    begin
      app = Application.create_app(app_name, [PHP_VERSION], @domain)
      assert false
    rescue OpenShift::OOException => e
      assert_equal 140, e.code
    end

    # test prefer region for app create when region enabled
    OpenShift::MCollectiveApplicationContainerProxy.stubs('rpc_get_fact').multiple_yields(["s00", 100], ["s10", 100])
    Rails.configuration.msg_broker[:regions][:enabled] = true
    Rails.configuration.msg_broker[:regions][:require_for_app_create] = false
    region1 = Region.create("g1")
    region1.add_zone("z10")
    dist.add_node("s10", "g1", "z10")
    app = Application.create_app(app_name, [PHP_VERSION], @domain)
    assert_equal app.gears.count, 1
    assert_equal "s10", app.gears.first.server_identity
    app.destroy_app

    # test all app gears in same region and gears in group instance should belong to different zones
    Rails.configuration.msg_broker[:regions][:enabled] = true
    Rails.configuration.msg_broker[:regions][:require_for_app_create] = true
    OpenShift::MCollectiveApplicationContainerProxy.stubs('rpc_get_fact').multiple_yields(["s10", 100], ["s20", 100], ["s11", 100], ["s21", 100])
    region1.add_zone("z11")
    dist.add_node("s11", "g1", "z11")
    region2 = Region.create("g2")
    region2.add_zone("z20")
    region2.add_zone("z21")
    dist.add_node("s20", "g2", "z20")
    dist.add_node("s21", "g2", "z21")

    app = Application.create_app(app_name, [PHP_VERSION, MYSQL_VERSION], @domain, nil, true)
    app = Application.find_by(canonical_name: app_name.downcase, domain_id: @domain._id) rescue nil
    web_framework_component_instance = app.component_instances.select{ |c| CartridgeCache.find_cartridge(c.cartridge_name).categories.include?("web_framework") }.first
    app.scale_by(web_framework_component_instance.group_instance_id, 1)
    app.reload
    assert_equal app.gears.count, 3
    assert_equal app.group_instances.count, 2
    si1, si2, si3 = nil, nil, nil
    app.group_instances.each do |gi|
      if gi.gears.count == 2
        si1 = District.find_server(gi.gears.first.server_identity)
        si2 = District.find_server(gi.gears.last.server_identity)
        assert_not_equal "s00", si1.name
        assert_not_equal "s00", si2.name
      else
        si3 = District.find_server(gi.gears.first.server_identity)
        assert_not_equal "s00", si3.name
      end
    end
    assert_not_nil si1
    assert_not_nil si2
    assert_not_nil si3
    assert_equal si1.region_id, si2.region_id
    assert_equal si2.region_id, si3.region_id
    assert_not_equal si1.zone_id, si2.zone_id

    app.destroy_app 
    dist.deactivate_node("s00")
    dist.deactivate_node("s10")
    dist.deactivate_node("s11")
    dist.deactivate_node("s20")
    dist.deactivate_node("s21")
    dist.remove_node("s00")
    dist.remove_node("s10")
    dist.remove_node("s11")
    dist.remove_node("s20")
    dist.remove_node("s21")
    region1.remove_zone("z10")
    region1.remove_zone("z11")
    region2.remove_zone("z20")
    region2.remove_zone("z21")
    region1.delete
    region2.delete
    dist.destroy
    assert(District.count == 0)
    assert(Region.count == 0)
  end

  def teardown
    District.delete_all
    Region.delete_all
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
