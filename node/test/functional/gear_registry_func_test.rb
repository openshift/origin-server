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

class DeploymentFuncTest < OpenShift::NodeTestCase
  GEAR_BASE_DIR = '/var/lib/openshift'

  def setup
    @uid = 5997

    @config.stubs(:get).with("GEAR_BASE_DIR").returns(GEAR_BASE_DIR)
    @config.stubs(:get).with("GEAR_GECOS").returns('Functional Test')
    @config.stubs(:get).with("CREATE_APP_SYMLINKS").returns('0')
    @config.stubs(:get).with("GEAR_SKEL_DIR").returns(nil)
    @config.stubs(:get).with("GEAR_SHELL").returns(nil)
    @config.stubs(:get).with("CLOUD_DOMAIN").returns('example.com')
    @config.stubs(:get).with("OPENSHIFT_HTTP_CONF_DIR").returns('/etc/httpd/conf.d/openshift')
    @config.stubs(:get).with("PORT_BEGIN").returns(nil)
    @config.stubs(:get).with("PORT_END").returns(nil)
    @config.stubs(:get).with("PORTS_PER_USER").returns(5)
    @config.stubs(:get).with("UID_BEGIN").returns(@uid)
    @config.stubs(:get).with("BROKER_HOST").returns('localhost')
    @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns('.')

    @uuid = `uuidgen -r |sed -e s/-//g`.chomp

    begin
      %x(userdel -f #{Etc.getpwuid(@uid).name})
    rescue ArgumentError
    end

    @container = OpenShift::Runtime::ApplicationContainer.new(@uuid, @uuid, @uid, "AppRepoFuncTest", "AppRepoFuncTest", "functional-test")
    @container.create
  end

  def teardown
    @container.destroy unless ENV['KEEP_CONTAINER']
  end

  def assert_registry_entries_equal(a, b)
    assert_equal a.keys, b.keys
    assert_equal a.values.map(&:to_s), b.values.map(&:to_s)
  end

  def test_initialize_creates_files
    refute_path_exist File.join(@container.container_dir, 'gear_registry.txt')
    refute_path_exist File.join(@container.container_dir, 'gear_registry.lock')

    registry = OpenShift::Runtime::GearRegistry.new(@container)

    assert_path_exist File.join(@container.container_dir, 'gear_registry.txt')
    assert_path_exist File.join(@container.container_dir, 'gear_registry.lock')

    assert_equal Hash.new, registry.entries
  end

  def test_initialize_loads_entries
    File.open(File.join(@container.container_dir, 'gear_registry.txt'), "w") do |f|
      5.times { |i| f.write "uuid#{i},namespace#{i},dns#{i},ip#{i},port#{i}\n" }
    end

    expected_entries = {}
    5.times do |i|
      entry = OpenShift::Runtime::GearRegistry::Entry.new(uuid: "uuid#{i}",
                                                          namespace: "namespace#{i}",
                                                          dns: "dns#{i}",
                                                          private_ip: "ip#{i}",
                                                          proxy_port: "port#{i}")
      expected_entries["uuid#{i}"] = entry
    end

    registry = OpenShift::Runtime::GearRegistry.new(@container)
    assert_registry_entries_equal expected_entries, registry.entries
  end

  def test_entries
    File.open(File.join(@container.container_dir, 'gear_registry.txt'), "w") do |f|
      5.times { |i| f.write "uuid#{i},namespace#{i},dns#{i},ip#{i},port#{i}\n" }
    end

    registry = OpenShift::Runtime::GearRegistry.new(@container)
    copy = registry.entries
    copy["uuid1"] = "xyz"

    copy2 = registry.entries
    assert_equal "uuid1,namespace1,dns1,ip1,port1", copy2["uuid1"].to_s
  end

  def test_update
    File.open(File.join(@container.container_dir, 'gear_registry.txt'), "w") do |f|
      2.times { |i| f.write "uuid#{i},namespace#{i},dns#{i},ip#{i},port#{i}\n" }
    end

    uuid1 = OpenShift::Runtime::GearRegistry::Entry.new(uuid: "uuid1",
                                                        namespace: "namespace1",
                                                        dns: "dns1",
                                                        private_ip: "ip1",
                                                        proxy_port: "port1")

    new_entry1 = OpenShift::Runtime::GearRegistry::Entry.new(uuid: "abc1",
                                                             namespace: "def1",
                                                             dns: "ghi1",
                                                             private_ip: "jkl1",
                                                             proxy_port: "mno1")

    new_entry2 = OpenShift::Runtime::GearRegistry::Entry.new(uuid: "abc2",
                                                             namespace: "def2",
                                                             dns: "ghi2",
                                                             private_ip: "jkl2",
                                                             proxy_port: "mno2")


    registry = OpenShift::Runtime::GearRegistry.new(@container)

    original_entries = registry.entries
    original_entries.delete("uuid0")
    updated_registry = {"abc1" => new_entry1, "abc2" => new_entry2}
    updated_registry.merge!(original_entries)

    new_gears = registry.update(updated_registry)
    new_gear_uuids = new_gears.map(&:uuid)
    %w(abc1 abc2).each { |uuid| assert_includes new_gear_uuids, uuid }

    updated_entries = registry.entries
    assert_equal 3, updated_entries.size
    assert_equal updated_entries["uuid1"].to_s, uuid1.to_s
    assert_equal updated_entries["abc1"].to_s, new_entry1.to_s
    assert_equal updated_entries["abc2"].to_s, new_entry2.to_s
  end

  def test_ssh_urls
    File.open(File.join(@container.container_dir, 'gear_registry.txt'), "w") do |f|
      2.times { |i| f.write "uuid#{i},namespace#{i},dns#{i},ip#{i},port#{i}\n" }
    end

    registry = OpenShift::Runtime::GearRegistry.new(@container)
    ssh_urls = registry.ssh_urls
    assert_includes ssh_urls, "uuid0@dns0"
    assert_includes ssh_urls, "uuid1@dns1"
  end
end