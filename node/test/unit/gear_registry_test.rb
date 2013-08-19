#!/usr/bin/env oo-ruby
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

class GearRegistryTest < OpenShift::NodeTestCase
  def setup
    @test_dir = File.join('/tmp', time_to_s(Time.now))
    FileUtils.mkpath(@test_dir)

    @registry_file = File.join(@test_dir, 'gear_registry.txt')
    @registry_lock_file = File.join(@test_dir, 'gear_registry.lock')
  end

  def teardown
    FileUtils.rm_rf(@test_dir)
  end

  def create_entry(suffix)
    options = {uuid: "uuid#{suffix}",
               namespace: "namespace#{suffix}",
               dns: "dns#{suffix}",
               private_ip: "private_ip#{suffix}",
               proxy_port: "proxy_port#{suffix}"}

    entry = ::OpenShift::Runtime::GearRegistry::Entry.new(options)
  end

  def time_to_s(time)
    time.strftime("%Y-%m-%d_%H-%M-%S.%L")
  end

  def test_entry_initialize
    entry = create_entry("1")

    assert_equal 'uuid1', entry.uuid
    assert_equal 'namespace1', entry.namespace
    assert_equal 'dns1', entry.dns
    assert_equal 'private_ip1', entry.private_ip
    assert_equal 'proxy_port1', entry.proxy_port
  end

  def test_entry_to_s
    entry = create_entry("1")

    assert_equal "uuid1,namespace1,dns1,private_ip1,proxy_port1", entry.to_s
  end

  def test_gear_registry_initialize_creates_files
    container = mock('container')
    container.expects(:container_dir).returns(@test_dir).times(2)
    container.expects(:set_rw_permission).with(@registry_file)
    container.expects(:set_rw_permission).with(@registry_lock_file)

    registry = ::OpenShift::Runtime::GearRegistry.new(container)

    assert_path_exist @registry_file
    assert_equal 0o100644, File.stat(@registry_file).mode
    assert_path_exist @registry_lock_file
    assert_equal 0o100644, File.stat(@registry_lock_file).mode
    assert_empty registry.entries
  end

  def test_gear_registry_initialize_files_already_exist
    container = mock('container')
    container.expects(:container_dir).returns(@test_dir).times(2)
    container.expects(:set_rw_permission).never

    File.new(@registry_file, 'w')
    File.new(@registry_lock_file, 'w')

    File.expects(:new).never

    registry = ::OpenShift::Runtime::GearRegistry.new(container)

    assert_path_exist @registry_file
    assert_path_exist @registry_lock_file
    assert_empty registry.entries
  end

  def test_gear_registry_initialize_loads_existing
    container = mock('container')
    container.expects(:container_dir).returns(@test_dir).times(2)
    container.expects(:set_rw_permission).never

    File.open(@registry_file, 'w') do |f|
      f.write "uuid1,namespace1,dns1,private_ip1,proxy_port1\nuuid2,namespace2,dns2,private_ip2,proxy_port2"
    end
    File.new(@registry_lock_file, 'w')

    File.expects(:new).never

    registry = ::OpenShift::Runtime::GearRegistry.new(container)

    assert_path_exist @registry_file
    assert_path_exist @registry_lock_file
    entries = registry.entries
    assert_equal 2, entries.size
    assert_equal "uuid1,namespace1,dns1,private_ip1,proxy_port1", entries['uuid1'].to_s
    assert_equal "uuid2,namespace2,dns2,private_ip2,proxy_port2", entries['uuid2'].to_s
  end

  def test_update
    container = mock('container')
    container.expects(:container_dir).returns(@test_dir).times(2)
    container.expects(:set_rw_permission).with(@registry_file)
    container.expects(:set_rw_permission).with(@registry_lock_file)

    registry = ::OpenShift::Runtime::GearRegistry.new(container)
    updates = {'uuid1' => create_entry("1"), 'uuid2' => create_entry("2")}

    new_gears = registry.update(updates)

    assert_equal 2, new_gears.size
    assert_includes new_gears.map(&:uuid), 'uuid1'
    assert_includes new_gears.map(&:uuid), 'uuid2'

    entries = registry.entries
    assert_equal 2, entries.size
    assert_equal "uuid1,namespace1,dns1,private_ip1,proxy_port1", entries['uuid1'].to_s
    assert_equal "uuid2,namespace2,dns2,private_ip2,proxy_port2", entries['uuid2'].to_s

    updates = updates = {'uuid1' => create_entry("1"), 'uuid3' => create_entry("3")}

    new_gears = registry.update(updates)

    assert_equal 1, new_gears.size
    assert_equal 'uuid3', new_gears[0].uuid

    entries = registry.entries
    assert_equal 2, entries.size
    assert_equal "uuid1,namespace1,dns1,private_ip1,proxy_port1", entries['uuid1'].to_s
    assert_equal "uuid3,namespace3,dns3,private_ip3,proxy_port3", entries['uuid3'].to_s
  end

  def test_ssh_urls
    container = mock('container')
    container.expects(:container_dir).returns(@test_dir).times(2)
    container.expects(:set_rw_permission).with(@registry_file)
    container.expects(:set_rw_permission).with(@registry_lock_file)

    registry = ::OpenShift::Runtime::GearRegistry.new(container)
    updates = {'uuid1' => create_entry("1"), 'uuid2' => create_entry("2")}

    new_gears = registry.update(updates)
    ssh_urls = registry.ssh_urls
    assert_equal 2, ssh_urls.size
    assert_includes ssh_urls, 'uuid1@dns1'
    assert_includes ssh_urls, 'uuid2@dns2'
  end
end