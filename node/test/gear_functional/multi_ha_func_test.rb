#--
# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

require_relative '../test_helper'
require 'fileutils'

class MultiHaFuncTest < OpenShift::NodeBareTestCase
  def setup
    @api = FunctionalApi.new
    @namespace = @api.create_domain

    @api.up_gears(10)
    @api.enable_ha

    @framework_cartridge = ENV['CART_TO_TEST'] || 'mock-0.1'
    logger.info("Using framework cartridge: #{@framework_cartridge}")
  end

  def teardown
    @api.delete_domain unless @api.nil? || ENV['PRESERVE']
  end

  def test_ha_enable
    app_name = "app#{@api.random_string}"

    app_id = @api.create_application(app_name, [@framework_cartridge], true)

    app_container = OpenShift::Runtime::ApplicationContainer.from_uuid(app_id)
    gear_registry = OpenShift::Runtime::GearRegistry.new(app_container)

    entries = gear_registry.entries
    logger.info("Gear registry contents: #{entries}")

    web_entries = entries[:web]
    assert_equal 1, web_entries.keys.size

    proxy_entries = entries[:proxy]
    assert_equal 1, proxy_entries.keys.size

    logger.info "Enabling HA for #{app_name}"
    @api.make_ha(app_name)

    gear_registry.load
    entries = gear_registry.entries
    logger.info("Gear registry contents: #{entries}")

    web_entries = entries[:web]
    assert_equal 2, web_entries.keys.size

    proxy_entries = entries[:proxy]
    assert_equal 2, proxy_entries.keys.size

    @api.assert_scales_to(app_name, @framework_cartridge, 3)
    @api.assert_scales_to(app_name, @framework_cartridge, 4)
    @api.assert_scales_to(app_name, @framework_cartridge, 5)

    gear_registry.load

    entries = gear_registry.entries
    proxy_entries = entries[:proxy]

    # test restart
    assert_proxies_disabled(proxy_entries)
    @api.restart_cartridge(app_name, @framework_cartridge)
    assert_proxies_disabled(proxy_entries)

    @api.add_env_vars(app_name,[{name:"OPENSHIFT_HAPROXY_GEAR_RATIO",value:"4"}])
    @api.assert_scales_to(app_name, @framework_cartridge, 6)
    assert_proxies_not_disabled(proxy_entries)
    @api.assert_scales_to(app_name, @framework_cartridge, 7)
    assert_proxies_disabled(proxy_entries)    
    

  end

  def assert_proxies_disabled(proxy_entries)
    proxy_entries.values.each do |target_gear|
      proxy_entries.values.each do |proxy|
        logger.info "Checking target gear #{target_gear.dns} status from proxy #{proxy.dns}"
        @api.assert_gear_status_in_proxy(proxy, target_gear, 'MAINT')
      end
    end
  end

  def assert_proxies_not_disabled(proxy_entries)
    proxy_entries.values.each do |target_gear|
      proxy_entries.values.each do |proxy|
        logger.info "Checking target gear #{target_gear.dns} status from proxy #{proxy.dns}"
        @api.assert_gear_status_in_proxy(proxy, target_gear, 'UP')
      end
    end
  end

end
