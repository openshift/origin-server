ENV["TEST_NAME"] = "functional_application_test"
require_relative '../test_helper'
require 'openshift-origin-controller'
require_relative '../helpers/rest/api'

class ApplicationsTest < ActionDispatch::IntegrationTest
  def setup
    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = 'password'
    @namespace = "domain" + gen_uuid[0..9]
    @user = CloudUser.new(login: @login)
    @user.max_gears = 10
    @user.save!
    @domain = Domain.new(namespace: @namespace, owner: @user)
    @domain.save!
    @appname = "test" + gen_uuid[0..9]
    Lock.create_lock(@user.id)
    register_user(@login, @password)
    stubber
  end

  def region_stubber
    OpenShift::ApplicationContainerProxy.unstub(:find_available)
    Rails.configuration.msg_broker[:districts][:enabled] = true
    container = OpenShift::ApplicationContainerProxy.instance("node_dns")
    OpenShift::ApplicationContainerProxy.stubs(:instance).returns(container)
    container.stubs(:get_capacity).returns(0)
    container.stubs(:get_node_profile).returns(Rails.configuration.openshift[:default_gear_size])
    container.stubs(:set_district)
  end

  test "create application valid gear size configuration" do
    restricted_cart_name = "mock-no-small"
    CartridgeType.where(:name => restricted_cart_name).delete
    restricted_cart = CartridgeType.new(
        :base_name => restricted_cart_name,
        :cartridge_vendor => 'redhat',
        :name => restricted_cart_name,
        :text => {'Name' => restricted_cart_name}.to_json,
        :version => '1.0'
        )
    restricted_cart.provides = restricted_cart.names
    assert restricted_cart.activate!
    restricted_cart_instances = [CartridgeInstance.new(restricted_cart)]

    unrestricted_cart_instances = try_cartridge_instances_for(:php)
    assert(unrestricted_cart_instances.size == 1, "Expected a single cartridge")
    unrestricted_cart_name = unrestricted_cart_instances[0].name

    valid_gear_sizes = Rails.application.config.openshift[:cartridge_gear_sizes]
    user_valid_gear_sizes = @user.capabilities["gear_sizes"]
    assert(user_valid_gear_sizes.include?("small"))

    unrestricted_cart_valid_gear_sizes = valid_gear_sizes[unrestricted_cart_name]
    assert_equal(unrestricted_cart_valid_gear_sizes, [])

    restricted_cart_valid_gear_sizes = valid_gear_sizes[restricted_cart_name]
    assert(!restricted_cart_valid_gear_sizes.empty? && !restricted_cart_valid_gear_sizes.include?("small"))

    blacklisted_words = OpenShift::ApplicationContainerProxy.get_blacklisted
    @appname = blacklisted_words.first if blacklisted_words.present?
    Gear.any_instance.expects(:publish_routing_info).never
    Gear.any_instance.expects(:unpublish_routing_info).never

    opts = {:default_gear_size => "small"}
    assert_raise(OpenShift::UserException){ Application.create_app(@appname, restricted_cart_instances, @domain, opts) }

    app = Application.create_app(@appname, unrestricted_cart_instances, @domain, opts)
    app.destroy_app
    assert_equal(false, Application.where(canonical_name: @appname.downcase).exists?)
  end

  test "create update and destroy application" do
    blacklisted_words = OpenShift::ApplicationContainerProxy.get_blacklisted
    @appname = blacklisted_words.first if blacklisted_words.present?

    Gear.any_instance.expects(:publish_routing_info).never
    Gear.any_instance.expects(:unpublish_routing_info).never
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil
    assert_equal 1, app.group_instances.length
    assert_equal 1, app.gears.length

    new_config = {'auto_deploy' => true, 'deployment_branch' => "stage", 'keep_deployments' => 3, 'deployment_type' => "binary"}
    app.update_configuration(new_config)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    assert app.config['auto_deploy'] == true
    assert app.config['deployment_branch'] == "stage"
    assert app.config['keep_deployments'] == 3
    assert app.config['deployment_type'] == "binary"

    app.destroy_app
    assert_equal(false, Application.where(canonical_name: @appname.downcase).exists?)
  end

  test "initial app save failure should clean up gears" do
    e = RuntimeError.new("Failure")
    Application.any_instance.expects(:save!).raises(e)
    assert_difference "@user.consumed_gears", 0 do
      assert_difference "Application.where(:domain => @domain).count", 0 do
        assert_raises(RuntimeError){ Application.create_app(@appname, cartridge_instances_for(:php), @domain) }
      end
    end
  end

  test "pending operations reflected in cartridges queue" do
    app = Application.new
    assert e = app.cartridges
    assert EnumeratorArray === e
    assert_equal [], e.to_a
    assert_not_same e, app.cartridges

    app.pending_op_groups << AddFeaturesOpGroup.new(features: [php_version, mysql_version])
    assert_equal [], app.cartridges.to_a
    assert_equal [php_version, mysql_version], app.cartridges(true).to_a.map(&:name)

    app.pending_op_groups << RemoveFeaturesOpGroup.new(features: [mysql_version])
    assert_equal [], app.cartridges.to_a
    assert_equal [php_version], app.cartridges(true).to_a.map(&:name)

    Application.any_instance.expects(:save!)
    Application.any_instance.expects(:run_jobs)
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain)
    assert !app.persisted?

    assert_equal [php_version, mysql_version].sort, app.cartridges.to_a.map(&:name).sort
    # FIXME: should remove carts that are identical except for their ID, and prefer pending carts to
    # non pending carts
    assert_equal [php_version, mysql_version, php_version, mysql_version].sort, app.cartridges(true).to_a.map(&:name).sort
  end

  test "create update and destroy scalable application" do
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, :scalable => true, :initial_git_url => "https://a:b@github.com/foobar/test.git")
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    assert_equal "https://github.com/foobar/test.git", app.init_git_url
    new_config = {'auto_deploy' => true, 'deployment_branch' => "stage", 'keep_deployments' => 3, 'deployment_type' => "binary"}
    app.update_configuration(new_config)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    assert_equal true, app.config['auto_deploy']
    assert_equal 3, app.config['keep_deployments']
    assert_equal "binary",  app.config['deployment_type']

    app.destroy_app
  end

  test "create test and destroy available application" do
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, :available => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    assert_equal true, app.scalable
    assert_equal true, app.ha
    assert_equal 3, app.gears.count

    app.destroy_app
  end

  test "make an application highly available" do
    @user.ha=true
    @user.save
    app = Application.create_app(@appname, cartridge_instances_for(:php), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    assert_equal true, app.scalable
    assert_not_equal true, app.ha
    assert_equal 1, app.gears.count

    # scale up, get 1 more php instance
    app.scale_by(app.group_instances.first._id, 1)
    app.reload
    assert_equal 2, app.gears.count
    assert_equal 1, app.gears.inject(0){ |c, g| c + (g.sparse_carts.present? ? 1 : 0) }
    assert_equal [app.component_instances.detect{ |i| i.cartridge.is_web_proxy? }._id], app.gears.map(&:sparse_carts).flatten.uniq

    # make app ha and scale up, get 1 more php instance
    app.make_ha
    app.scale_by(app.group_instances.first._id, 1)
    app.reload
    assert_equal 3, app.gears.count
    assert_equal 2, app.gears.inject(0){ |c, g| c + (g.sparse_carts.present? ? 1 : 0) }
    assert_equal [app.component_instances.detect{ |i| i.cartridge.is_web_proxy? }._id], app.gears.map(&:sparse_carts).flatten.uniq

    # scale down, php instance goes away
    app.scale_by(app.group_instances.first._id, -1)
    assert_equal 2, app.gears.count
    assert_equal 2, app.gears.inject(0){ |c, g| c + (g.sparse_carts.present? ? 1 : 0) }

    # alter multiplier to 1, expect new haproxy gear
    stubs_config(:openshift, default_ha_multiplier: 1)
    app.scale_by(app.group_instances.first._id, 1)
    assert_equal 3, app.gears.count
    assert_equal 3, app.gears.inject(0){ |c, g| c + (g.sparse_carts.present? ? 1 : 0) }

    app.scale_by(app.group_instances.first._id, -1)

    # alter multiplier to 2
    stubs_config(:openshift, default_ha_multiplier: 2)
    app.scale_by(app.group_instances.first._id, 3)
    assert_equal 5, app.gears.count
    assert_equal 3, app.gears.inject(0){ |c, g| c + (g.sparse_carts.present? ? 1 : 0) }

    # scale up, get 1 more haproxy instance
    app.scale_by(app.group_instances.first._id, 1)
    assert_equal 6, app.gears.count
    assert_equal 3, app.gears.inject(0){ |c, g| c + (g.sparse_carts.present? ? 1 : 0) }

    # scale down, haproxy instances should remain the same
    app.scale_by(app.group_instances.first._id, -1)
    assert_equal 5, app.gears.count
    assert_equal 3, app.gears.inject(0){ |c, g| c + (g.sparse_carts.present? ? 1 : 0) }

    # scale down, 1 haproxy instance should get removed
    app.scale_by(app.group_instances.first._id, -1)
    assert_equal 4, app.gears.count
    assert_equal 2, app.gears.inject(0){ |c, g| c + (g.sparse_carts.present? ? 1 : 0) }

    app.destroy_app
  end

  test "jenkins-client and builders are dependent on jenkins app" do
    builder = Application.create_app("#{@appname}j", cartridge_instances_for(:jenkins), @domain)
    builder =  Application.find(builder._id)
    assert_equal 1, builder.gears.count

    app = Application.create_app(@appname, cartridge_instances_for(:php, 'jenkins-client'), @domain, scalable: true)
    app = Application.find(app._id)
    assert_equal 1, app.gears.count
    assert_equal 1, app.group_instances.count

    built = Application.create_app("#{@appname}b", cartridge_instances_for(:php), @domain, builder_id: builder._id)
    assert_equal 1, built.gears.count
    assert_equal 1, built.group_instances.count

    # removing Jenkins removes the client cart and any builders
    builder.destroy_app
    app.reload
    assert_equal 2, app.cartridges.count
    # builder was deleted
    assert_raises(Mongoid::Errors::DocumentNotFound){ Application.find(built._id) }

    app.destroy_app
  end

  test "cartridges are added based on requirements" do
    app = Application.create_app(@appname, cartridge_instances_for(:php), @domain)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    phpmyadmin = cartridge_instances_for(:phpmyadmin).map(&:cartridge)
    assert_raises(OpenShift::UserException){ app.add_cartridges(phpmyadmin) }
    begin
      app.add_cartridges(phpmyadmin)
    rescue OpenShift::UserException => e
      assert e.message =~ /Cartridge .* can not be added without/, e.message
    end
  end

  test "cartridges ignore existing requirements" do
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql, :phpmyadmin), @domain)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    assert_equal 3, app.cartridges.length, app.cartridges.map(&:name)
    assert_equal 1, app.cartridges.select{ |c| c.names.include?('php') }.count
    assert_equal 1, app.cartridges.select{ |c| c.names.include?('mysql') || c.names.include?('mariadb') }.count
    assert_equal 1, app.cartridges.select{ |c| c.names.include?('phpmyadmin') }.count
  end

  test "cartridges check conflicts" do
    app = Application.create_app(@appname, cartridge_instances_for(:php), @domain)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    carts = cartridge_instances_for(:mysql, :phpmyadmin).map(&:cartridge)
    app.add_cartridges(carts)

    assert_equal 3, app.cartridges.length, app.cartridges.map(&:name)
    assert_equal 1, app.cartridges.select{ |c| c.names.include?('php') }.count
    assert_equal 1, app.cartridges.select{ |c| c.names.include?('mysql') || c.names.include?('mariadb') }.count
    assert_equal 1, app.cartridges.select{ |c| c.names.include?('phpmyadmin') }.count
  end

  test "app config validation" do
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    app.config = nil
    assert_equal true, app.invalid?, "config validation failed"

    app.config = {'auto_deploy' => nil, 'deployment_branch' => nil, 'keep_deployments' => nil, 'deployment_type' => nil}
    assert app.invalid?, "config validation failed"
    assert_equal app.errors.messages[:config].length, 4, "Wrong number of error messages"

    #reset config and try individual fields
    app.config = {'auto_deploy' => true, 'deployment_branch' => 'master', 'keep_deployments' => 1, 'deployment_type' => 'git'}
    assert app.valid?, "config validation failed where it should have succeeded"

    app.config['auto_deploy'] = 'blah'
    assert app.invalid?, "auto_deploy validation failed"
    assert_equal app.errors.messages[:config].length, 1, "Wrong number of error messages"

    app.config['deployment_branch'] = "0" * 999
    assert app.invalid?, "deployment_branch validation failed"
    assert_equal app.errors.messages[:config].length, 2, "Wrong number of error messages"

    app.config['keep_deployments'] = -1
    assert app.invalid?, "keep_deployments validation failed"
    assert_equal app.errors.messages[:config].length, 3, "Wrong number of error messages"

    app.config['deployment_type'] = "blah"
    assert app.invalid?, "deployment_type validation failed"
    assert_equal app.errors.messages[:config].length, 4, "Wrong number of error messages"

    #check validation on update_config
    assert_raise(OpenShift::UserException){app.update_configuration(app.config)}
  end

  test "app metadata validation" do
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    [nil, {}, {'bar' => 1}, {'bar' => '1'}, {'bar' => []}, {'bar' => ['1']}, {'bar' => [1]}].each do |value|
      app.meta = value
      assert_equal true, app.valid?, "Value #{value.inspect} should be allowed"
    end

    app.meta = {:bar => 1}
    assert_equal true, app.invalid?, "meta validation failed"
    assert_equal ['Key bar is not a string'], app.errors.messages[:meta]

    app.meta = {'bar' => :baz}
    assert_equal true, app.invalid?, "meta validation failed"
    assert_equal ['Value for \'bar\' must be a string, number, or list of strings and numbers'], app.errors.messages[:meta]

    app.meta = {'bar' => [:baz]}
    assert_equal true, app.invalid?, "meta validation failed"
    assert_equal ['The array of values provided for \'bar\' must be strings or numbers'], app.errors.messages[:meta]

    app.meta = {'bar' => ['baz'*5000]}
    assert_equal true, app.invalid?, "meta validation failed"
    assert_equal ['Application metadata may not be larger than 10KB - currently 14KB'], app.errors.messages[:meta]
  end

  test "scalable application events" do
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil
    app.restart
    app.stop
    app.start
    app.tidy
    assert_raise(OpenShift::UserException){app.threaddump}

    as = "as.#{gen_uuid[0..9]}"
    app.add_alias(as)
    app.remove_alias(as)

    app.destroy_app
  end

  test "threaddump application events" do
    app = Application.create_app(@appname, cartridge_instances_for(:ruby, :mysql), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil
    app.threaddump
    app.destroy_app
  end

  test "scaling and storage events on application" do
    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil
    assert_equal 2, app.gears.length
    assert_equal [], app.group_overrides

    _, updated = app.elaborate(app.cartridges, [])
    changes, moves = app.compute_diffs(app.group_instances_with_overrides, updated, {})
    assert changes.all?{ |c| c.added.empty? && c.removed.empty? && c.gear_change == 0 && c.additional_filesystem_change == 0 }, changes.inspect
    assert_equal true, moves.empty?, moves.inspect

    @user.max_untracked_additional_storage = 5
    @user.save
    app.reload
    app.owner.reload

    component_instance = app.component_instances.find_by(cartridge_name: php_version)
    web_instance = app.web_component_instance
    specs = component_instance.group_instance.all_component_instances.map(&:to_component_spec)

    app.update_component_limits(component_instance, 1, 2, nil)
    assert_equal 2, (app = Application.find(app._id)).gears.length
    assert_equal [GroupOverride.new(specs, nil, 2)], app.group_overrides

    app.scale_by(web_instance.group_instance_id, 1)
    assert_equal 3, (app = Application.find(app._id)).gears.length
    assert_equal [GroupOverride.new(specs, nil, 2)], app.group_overrides

    app.update_component_limits(component_instance, 2, 2, nil)
    assert_equal 3, (app = Application.find(app._id)).gears.length
    assert_equal [GroupOverride.new(specs, 2, 2)], app.group_overrides

    app.update_component_limits(component_instance, nil, nil, 2)
    assert_equal 3, (app = Application.find(app._id)).gears.length
    assert_equal [GroupOverride.new(specs, 2, 2, nil, 2)], app.group_overrides

    app.update_component_limits(component_instance, 1, 2, nil)
    assert_equal 3, (app = Application.find(app._id)).gears.length
    assert_equal [GroupOverride.new(specs, nil, 2, nil, 2)], app.group_overrides

    app.update_component_limits(component_instance, 1, -1, nil)
    assert_equal 3, (app = Application.find(app._id)).gears.length
    assert_equal [GroupOverride.new(specs, nil, nil, nil, 2)], app.group_overrides

    app.scale_by(web_instance.group_instance_id, 1)
    app.reload
    assert_equal 4, app.gears.count

    app.scale_by(web_instance.group_instance_id, -1)
    resp = rest_check(:get, "", {})
    assert_equal resp.status, 200

    app.reload
    assert_equal 3, app.gears.count

    app.destroy_app
  end

  test "multiplier events on application" do
    app = Application.create_app(@appname, cartridge_instances_for(:php), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    web_instance = app.web_component_instance
    proxy_instance = app.component_instances.detect(&:is_web_proxy?)

    assert_equal [], app.group_overrides

    app.update_component_limits(proxy_instance, 1, 2, nil, nil)
    app.reload
    assert_equal 1, app.group_overrides.count
    proxy_go = app.group_overrides[0].components.find {|c| c.name == proxy_instance.component_name}
    assert_equal ComponentOverrideSpec, proxy_go.class
    assert_equal 1, proxy_go.min_gears
    assert_equal 2, proxy_go.max_gears
    assert_equal nil, proxy_go.multiplier

    app.update_component_limits(proxy_instance, nil, nil, nil, 2)
    app.reload
    assert_equal 1, app.group_overrides.count
    proxy_go = app.group_overrides[0].components.find {|c| c.name == proxy_instance.component_name}
    assert_equal ComponentOverrideSpec, proxy_go.class
    assert_equal 1, proxy_go.min_gears
    assert_equal 2, proxy_go.max_gears
    assert_equal 2, proxy_go.multiplier

    app.update_component_limits(proxy_instance, nil, nil, nil, 3)
    app.reload
    assert_equal 1, app.group_overrides.count
    proxy_go = app.group_overrides[0].components.find {|c| c.name == proxy_instance.component_name}
    assert_equal ComponentOverrideSpec, proxy_go.class
    assert_equal 1, proxy_go.min_gears
    assert_equal 2, proxy_go.max_gears
    assert_equal 3, proxy_go.multiplier

    app.destroy_app
  end

  test "application events through internal rest" do
    app = Application.create_app(@appname, cartridge_instances_for(:ruby, :mysql), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil

    resp = rest_check(:get, "", {})
    assert_equal resp.status, 200

    resp = rest_check(:put, "/cartridges/#{ruby_version}", { "scales_from" => 2, "scales_to" => 2})
    assert_equal 200, resp.status

    resp = rest_check(:put, "/cartridges/#{ruby_version}", {})
    assert_equal 422, resp.status

    resp = rest_check(:get, "/cartridges", {})
    assert_equal 200, resp.status

    resp = rest_check(:post, "/events", { "event" => "thread-dump" })
    assert_equal 200, resp.status

    resp = rest_check(:post, "/events", { "event" => "reload" })
    assert_equal 200, resp.status

    resp = rest_check(:post, "/events", { "event" => "tidy" })
    assert_equal 200, resp.status

    component_instance = app.component_instances.find_by(cartridge_name: ruby_version)
    assert group_instance = app.group_instances.detect{ |i| i.all_component_instances.include? component_instance }
    resp = rest_check(:get, "/gear_groups/#{group_instance._id.to_s}", { })
    assert_equal resp.status, 200

    app.destroy_app
  end

  test "application elaborate does not change overrides" do
    app = Application.create_app(@appname, cartridge_instances_for(:ruby), @domain, :scalable => true)
    assert_equal true, app.group_overrides.empty?

    overrides = [
      GroupOverride.new([app.component_instances.detect{ |i| i.is_web_framework? }]),
      GroupOverride.new([app.component_instances.detect{ |i| i.is_web_proxy? }]),
      GroupOverride.new(nil),
      GroupOverride.new([nil]),
      GroupOverride.new([ComponentSpec.new("test", "other")]),
    ]

    _, groups = app.elaborate(app.cartridges, overrides)
    assert_equal 1, groups.length
    assert_equal true, groups[0].implicit?

    app.reload

    overrides = [
      GroupOverride.new([app.component_instances.detect{ |i| i.is_web_framework? }]),
      GroupOverride.new([app.component_instances.detect{ |i| i.is_web_proxy? }]),
      GroupOverride.new(nil),
      GroupOverride.new([nil]),
      GroupOverride.new([ComponentSpec.new("test", "other")]),
    ]

    ops, added, removed = app.update_requirements(app.cartridges, nil, overrides)
    assert_equal 0, added
    assert_equal 0, removed
    assert_equal 1, ops.count
    assert_equal [], ops.first.group_overrides

    app.destroy_app
  end

  test "elaborate php and jenkins-client" do
    # non scalable app has plugin together with web framework
    _, overrides = Application.new.elaborate(cartridge_instances_for(:php, :'jenkins-client'), [])
    assert_equal 1, overrides.length
    assert_equal cartridge_instances_for(:php, :'jenkins-client').map(&:to_component_spec).sort, overrides[0].components
    assert_equal 1, overrides[0].min_gears
    assert_equal 1, overrides[0].max_gears
  end

  test "elaborate php and mysql" do
    # non scalable app has plugin together with web framework
    _, overrides = Application.new.elaborate(cartridge_instances_for(:php, :mysql), [])
    assert_equal 1, overrides.length
    assert_equal cartridge_instances_for(:php, :mysql).map(&:to_component_spec).sort, overrides[0].components
    assert_equal 1, overrides[0].min_gears
    assert_equal 1, overrides[0].max_gears
  end

  test "elaborate scalable php and jenkins-client" do
    # non scalable app has plugin together with web framework
    _, overrides = Application.new(:scalable => true).elaborate(cartridge_instances_for(:php, :'jenkins-client', :web_proxy), [])
    assert_equal 1, overrides.length
    assert_equal cartridge_instances_for(:php, :'jenkins-client', :web_proxy).map(&:to_component_spec).sort, overrides[0].components
    assert_equal 1, overrides[0].min_gears
    assert_equal -1, overrides[0].max_gears
  end

  test "elaborate scalable php, jenkins-client, and mysql" do
    # non scalable app has plugin together with web framework
    _, overrides = Application.new(:scalable => true).elaborate(cartridge_instances_for(:php, :'jenkins-client', :mysql, :web_proxy), [])
    assert_equal 2, overrides.length
    assert_equal cartridge_instances_for(:php, :'jenkins-client', :web_proxy).map(&:to_component_spec).sort, overrides[0].components
    assert_equal 1, overrides[0].min_gears
    assert_equal -1, overrides[0].max_gears

    assert_equal cartridge_instances_for(:mysql).map(&:to_component_spec).sort, overrides[1].components
    assert_equal 1, overrides[1].min_gears
    assert_equal 1, overrides[1].max_gears
  end


  test "update_requirements should detect new cartridge versions by id and add a pending op" do
    app = Application.create_app(@appname, cartridge_instances_for(:ruby), @domain)

    cart = OpenShift::Cartridge.new.from_descriptor(app.cartridges.first.to_descriptor)
    old_id = cart.id
    cart.id = "__new__"

    ops, add, remove = app.update_requirements([cart], nil, [])
    assert_equal 0, add
    assert_equal 0, remove
    assert ops.present?
    assert op = ops.find{ |o| UpdateCompIds === o }
    assert op.comp_specs.any?{ |c| c.id == '__new__' }
    assert op.saved_comp_specs.any?{ |c| c.id == old_id }
  end

  test "component configure order should prioritize web frameworks" do
    assert order = Application.new.calculate_configure_order(cartridge_instances_for('jenkins-client', :php).map(&:to_component_spec))
    assert_equal php_version, order[0].cartridge_name
  end

  test "user info through internal rest" do
    credentials = Base64.encode64("#{@user}:#{@password}")
    headers = {}
    headers["HTTP_ACCEPT"] = "application/json"
    headers["HTTP_AUTHORIZATION"] = "Basic #{credentials}"
    headers["REMOTE_USER"] = @user
    request_via_redirect(:get, "/broker/rest/user", {}, headers)
    assert_equal @response.status, 200
  end

  test "create scalable app and ensure gears belong to single region and different zones" do
    return unless OpenShift.const_defined?('MCollectiveApplicationContainerProxy')
    dist = get_district_obj
    dist.save!

    region_stubber
    # test require region for app create
    OpenShift::MCollectiveApplicationContainerProxy.stubs('rpc_get_fact').multiple_yields(["s00", 100])
    dist.add_node("s00")
    Rails.configuration.msg_broker[:regions][:require_zones_for_app_create] = true
    begin
      app = Application.create_app(@appname, cartridge_instances_for(:php), @domain)
      assert false
    rescue OpenShift::OOException => e
      assert_equal 140, e.code
    end

    # test prefer region for app create when region enabled
    OpenShift::MCollectiveApplicationContainerProxy.stubs('rpc_get_fact').multiple_yields(["s00", 100], ["s10", 100])
    Rails.configuration.msg_broker[:regions][:require_zones_for_app_create] = false
    region1 = Region.create("g1")
    region1.add_zone("z10")
    dist.add_node("s10", "g1", "z10")
    app = Application.create_app(@appname, cartridge_instances_for(:php), @domain)
    assert_equal app.gears.count, 1
    assert_equal "s10", app.gears.first.server_identity
    app.destroy_app

    # test all app gears in same region and gears in group instance should belong to different zones
    Rails.configuration.msg_broker[:regions][:require_zones_for_app_create] = true
    OpenShift::MCollectiveApplicationContainerProxy.stubs('rpc_get_fact').multiple_yields(["s00", 100], ["s10", 100], ["s20", 100], ["s11", 100], ["s21", 100])
    region1.add_zone("z11")
    dist.add_node("s11", "g1", "z11")
    region2 = Region.create("g2")
    region2.add_zone("z20")
    region2.add_zone("z21")
    dist.add_node("s20", "g2", "z20")
    dist.add_node("s21", "g2", "z21")

    app = Application.create_app(@appname, cartridge_instances_for(:php, :mysql), @domain, :scalable => true)
    app = Application.find_by(canonical_name: @appname.downcase, domain_id: @domain._id) rescue nil
    web_framework_component_instance = app.component_instances.select{ |c| CartridgeCache.find_cartridge(c.cartridge_name).categories.include?("web_framework") }.first
    app.scale_by(web_framework_component_instance.group_instance_id, 1)
    app.reload
    assert_equal app.gears.count, 3
    assert_equal app.group_instances.count, 2
    si1, si2, si3 = nil, nil, nil
    districts = [District.find(dist.id)]
    app.group_instances.each do |gi|
      if gi.gears.count == 2
        si1 = District.find_server(gi.gears.first.server_identity, districts)
        si2 = District.find_server(gi.gears.last.server_identity, districts)
        assert_not_equal "s00", si1.name
        assert_not_equal "s00", si2.name
      else
        si3 = District.find_server(gi.gears.first.server_identity, districts)
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

    # test min zones per gear group 
    Rails.configuration.msg_broker[:regions][:require_zones_for_app_create] = true
    Rails.configuration.msg_broker[:regions][:min_zones_per_gear_group] = 3
    OpenShift::MCollectiveApplicationContainerProxy.stubs('rpc_get_fact').multiple_yields(["s00", 100], ["s20", 100])
    app = Application.create_app(@appname, cartridge_instances_for(:php), @domain, :scalable => true)
    assert_equal 1, app.gears.length
    assert_equal "s20", app.gears[0].server_identity
    web_framework_component_instance = app.component_instances.select{ |c| CartridgeCache.find_cartridge(c.cartridge_name).categories.include?("web_framework") }.first
    exception_count = 0
    app.scale_by(web_framework_component_instance.group_instance_id, 1) rescue exception_count += 1
    assert_equal 1, exception_count
    OpenShift::MCollectiveApplicationContainerProxy.stubs('rpc_get_fact').multiple_yields(["s00", 100], ["s20", 100], ["s21", 100])
    app.scale_by(web_framework_component_instance.group_instance_id, 1)
    assert_equal 2, app.gears.count
    app.destroy_app

    # test zones even distribution
    Rails.configuration.msg_broker[:regions][:require_zones_for_app_create] = true
    Rails.configuration.msg_broker[:regions][:min_zones_per_gear_group] = 1
    OpenShift::MCollectiveApplicationContainerProxy.stubs('rpc_get_fact').multiple_yields(["s20", 100], ["s21", 99])
    app = Application.create_app(@appname, cartridge_instances_for(:php), @domain, :scalable => true)
    web_framework_component_instance = app.component_instances.select{ |c| CartridgeCache.find_cartridge(c.cartridge_name).categories.include?("web_framework") }.first
    OpenShift::MCollectiveApplicationContainerProxy.stubs('rpc_get_fact').multiple_yields(["s20", 99], ["s21", 100])
    app.scale_by(web_framework_component_instance.group_instance_id, 1)
    OpenShift::MCollectiveApplicationContainerProxy.stubs('rpc_get_fact').multiple_yields(["s20", 100], ["s21", 99])
    app.scale_by(web_framework_component_instance.group_instance_id, 1)
    OpenShift::MCollectiveApplicationContainerProxy.stubs('rpc_get_fact').multiple_yields(["s20", 99], ["s21", 100])
    app.scale_by(web_framework_component_instance.group_instance_id, 1)
    assert_equal 4, app.gears.count
    servers = []
    app.gears.each {|gear| servers << gear.server_identity }
    assert_equal ["s20", "s20", "s21", "s21"], servers.sort
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
    assert_equal false, District.where(_id: dist.id).exists?
    assert_equal false, Region.where(_id: region1.id).exists?
    assert_equal false, Region.where(_id: region2.id).exists?
    Rails.configuration.msg_broker[:regions][:require_zones_for_app_create] = false
  end

  def teardown
    @user.force_delete rescue nil
    Mocha::Mockery.instance.stubba.unstub_all
    Rails.cache.clear
  end

  private

  def rest_check(method, resource, params)
    uri = "/domains/#{@namespace}/applications/#{@appname}" + resource
    credentials = Base64.encode64("#{@login}:#{@password}")
    headers = {}
    headers["HTTP_ACCEPT"] = "application/json"
    headers["HTTP_AUTHORIZATION"] = "Basic #{credentials}"
    headers["REMOTE_USER"] = @login
    request_via_redirect(method, "/broker/rest" + uri, params, headers)
    @response
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
