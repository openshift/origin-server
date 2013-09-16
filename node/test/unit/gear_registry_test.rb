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

    @registry_file = File.join(@test_dir, 'gear_registry.json')
    @registry_lock_file = File.join(@test_dir, 'gear_registry.lock')

    @container = mock('container')
    @sample_json = <<EOF
{
  "web": {
    "uuid1": {
      "namespace": "namespace1",
      "dns": "dns1",
      "proxy_hostname": "proxy_host1",
      "proxy_port": 35561
    },
    "uuid2": {
      "namespace": "namespace2",
      "dns": "dns2",
      "proxy_hostname": "proxy_host2",
      "proxy_port": 35562
    }
  },
  "proxy": {
    "uuid3": {
      "namespace": "namespace3",
      "dns": "dns3",
      "proxy_hostname": "proxy_host3",
      "proxy_port": 35563
    },
    "uuid4": {
      "namespace": "namespace4",
      "dns": "dns4",
      "proxy_hostname": "proxy_host4",
      "proxy_port": 35564
    }
  }
}
EOF
  end

  def teardown
    FileUtils.rm_rf(@test_dir)
  end

  def create_empty_registry
    @container.expects(:container_dir).returns(@test_dir).times(2)
    @container.expects(:set_rw_permission).with(@registry_file)
    @container.expects(:set_rw_permission).with(@registry_lock_file)

    registry = ::OpenShift::Runtime::GearRegistry.new(@container)
  end

  def options_for_entry(suffix)
    {
      uuid: "uuid#{suffix}",
      namespace: "namespace#{suffix}",
      dns: "dns#{suffix}",
      proxy_hostname: "proxy_host#{suffix}",
      proxy_port: "3556#{suffix}".to_i
    }
  end

  def create_entry(suffix)
    options = options_for_entry(suffix)
    entry = ::OpenShift::Runtime::GearRegistry::Entry.new(options)
  end

  def entries_equal(a,b)
    a.uuid == b.uuid and
    a.namespace == b.namespace and
    a.dns == b.dns and
    a.proxy_hostname == b.proxy_hostname and
    a.proxy_port == b.proxy_port
  end

  def time_to_s(time)
    time.strftime("%Y-%m-%d_%H-%M-%S.%L")
  end

  def test_entry_initialize
    entry = create_entry("1")

    assert_equal 'uuid1', entry.uuid
    assert_equal 'namespace1', entry.namespace
    assert_equal 'dns1', entry.dns
    assert_equal 'proxy_host1', entry.proxy_hostname
    assert_equal 35561, entry.proxy_port
  end

  def test_entry_to_json
    entry = create_entry("1")

    assert_equal '{"namespace":"namespace1","dns":"dns1","proxy_hostname":"proxy_host1","proxy_port":35561}', entry.to_json
  end

  def test_gear_registry_initialize_creates_files
    registry = create_empty_registry

    assert_path_exist @registry_file
    assert_equal 0o100644, File.stat(@registry_file).mode
    assert_path_exist @registry_lock_file
    assert_equal 0o100644, File.stat(@registry_lock_file).mode
    assert_empty registry.entries
  end

  def test_gear_registry_initialize_files_already_exist
    @container.expects(:container_dir).returns(@test_dir).times(2)
    @container.expects(:set_rw_permission).never

    File.new(@registry_file, 'w')
    File.new(@registry_lock_file, 'w')

    File.expects(:new).never

    registry = ::OpenShift::Runtime::GearRegistry.new(@container)

    assert_path_exist @registry_file
    assert_path_exist @registry_lock_file
    assert_empty registry.entries
  end

  def test_gear_registry_initialize_loads_existing
    @container.expects(:container_dir).returns(@test_dir).times(2)
    @container.expects(:set_rw_permission).never

    File.open(@registry_file, 'w') { |f| f.write @sample_json }
    File.new(@registry_lock_file, 'w')

    File.expects(:new).never

    registry = ::OpenShift::Runtime::GearRegistry.new(@container)

    assert_path_exist @registry_file
    assert_path_exist @registry_lock_file
    entries = registry.entries
    assert_equal 2, entries.size
    assert_includes entries.keys, :web
    assert_includes entries.keys, :proxy
    web_entries = entries[:web]
    assert_equal 2, web_entries.size
    assert entries_equal(create_entry("1"), web_entries["uuid1"])
    assert entries_equal(create_entry("2"), web_entries["uuid2"])
    proxy_entries = entries[:proxy]
    assert_equal 2, proxy_entries.size
    assert entries_equal(create_entry("3"), proxy_entries["uuid3"])
    assert entries_equal(create_entry("4"), proxy_entries["uuid4"])
  end

  def test_entries_returns_a_copy
    registry = create_empty_registry
    registry.add({type: :web}.merge(options_for_entry("1")))
    registry.add({type: :web}.merge(options_for_entry("2")))
    registry.add({type: :proxy}.merge(options_for_entry("3")))
    registry.add({type: :proxy}.merge(options_for_entry("4")))

    copy1 = registry.entries
    copy1[:web]["uuid1"] = 123
    copy1[:proxy] = nil

    copy2 = registry.entries

    assert entries_equal(create_entry("1"), copy2[:web]["uuid1"])
    assert entries_equal(create_entry("2"), copy2[:web]["uuid2"])
    assert entries_equal(create_entry("3"), copy2[:proxy]["uuid3"])
    assert entries_equal(create_entry("4"), copy2[:proxy]["uuid4"])
  end

  def test_clear
    registry = create_empty_registry
    registry.add({type: :web}.merge(options_for_entry("1")))
    refute_empty registry.entries
    registry.clear
    assert_empty registry.entries
  end

  def test_save
    registry = create_empty_registry
    registry.add({type: :web}.merge(options_for_entry("1")))
    registry.add({type: :web}.merge(options_for_entry("2")))
    registry.add({type: :proxy}.merge(options_for_entry("3")))
    registry.add({type: :proxy}.merge(options_for_entry("4")))

    registry.save
    from_file = JSON.load(File.new(@registry_file))
    from_string = JSON.parse(@sample_json)
    assert_equal from_string, from_file
  end

  def test_to_json
    registry = create_empty_registry
    registry.add({type: :web}.merge(options_for_entry("1")))
    registry.add({type: :web}.merge(options_for_entry("2")))
    registry.add({type: :proxy}.merge(options_for_entry("3")))
    registry.add({type: :proxy}.merge(options_for_entry("4")))
    assert_equal JSON.parse(@sample_json).to_json, registry.to_json
  end
end
