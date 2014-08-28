#--
# Copyright 2013-2014 Red Hat, Inc.
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
require 'fakefs/safe'
require 'yaml'
require 'pp'

class NodeTest < OpenShift::NodeTestCase

  def setup
    FakeFS.activate!
    FakeFS::FileSystem.clear

    @path = '/var/lib/openshift/.cartridge_repository'
    OpenShift::Runtime::CartridgeRepository.instance.clear
  end

  def teardown
    FakeFS.deactivate!
  end

  def populate_manifest(manifests = {})
    manifests.each_pair do |manifest_file, manifest|
      FileUtils.mkpath File.dirname(manifest_file)
      File.open(manifest_file, 'w') { |file| file << manifest }
    end
  end

  def test_get_cartridge_list
    manifest = %q{#
        Name: crtest
        Display-Name: crtest Unit Test
        Cartridge-Short-Name: CRTEST
        Version: '0.3'
        Versions: ['0.1', '0.2', '0.3']
        Cartridge-Version: '0.0.1'
        Cartridge-Vendor: redhat
        Categories:
          - web_framework
        Group-Overrides:
          - components:
            - crtest-0.3
            - web_proxy
        Version-Overrides:
          '0.1':
            Group-Overrides:
              - components:
                - crtest-0.1
                - web_proxy
          '0.2':
            Group-Overrides:
              - components:
                - crtest-0.2
                - web_proxy
      }

    populate_manifest({"#{@path}/redhat-crtest/0.0.1/metadata/manifest.yml" => manifest})

    cr = OpenShift::Runtime::CartridgeRepository.instance
    cr.load

    buffer = OpenShift::Runtime::Node.get_cartridge_list(true, true, true)
    refute_nil buffer

    assert_equal %Q(CLIENT_RESULT: [\"---\\nName: crtest\\nDisplay-Name: crtest Unit Test\\nVersion: '0.3'\\nVersions:\\n- '0.1'\\n- '0.2'\\n- '0.3'\\nCategories:\\n- web_framework\\nCartridge-Version: 0.0.1\\nCartridge-Vendor: redhat\\nPlatform: linux\\nGroup-Overrides:\\n- components:\\n  - crtest-0.3\\n  - web_proxy\\n\",\"---\\nName: crtest\\nDisplay-Name: crtest Unit Test\\nVersion: '0.2'\\nVersions:\\n- '0.1'\\n- '0.2'\\n- '0.3'\\nCategories:\\n- web_framework\\nCartridge-Version: 0.0.1\\nCartridge-Vendor: redhat\\nPlatform: linux\\nGroup-Overrides:\\n- components:\\n  - crtest-0.2\\n  - web_proxy\\n\",\"---\\nName: crtest\\nDisplay-Name: crtest Unit Test\\nVersion: '0.1'\\nVersions:\\n- '0.1'\\n- '0.2'\\n- '0.3'\\nCategories:\\n- web_framework\\nCartridge-Version: 0.0.1\\nCartridge-Vendor: redhat\\nPlatform: linux\\nGroup-Overrides:\\n- components:\\n  - crtest-0.1\\n  - web_proxy\\n\"]), buffer
  end

  def test_node_utilization
    scenarios = [
        {:node_profile => 'small', :quota_blocks => '1048576', :quota_files => '80000', :max_active_gears => '80',
         :max_active_apps => nil, :no_overcommit_active => false},
        {:node_profile => 'medium', :quota_blocks => '2097152', :quota_files => '160000', :max_active_gears => nil,
         :max_active_apps => '40', :no_overcommit_active => false},
        {:node_profile => 'large', :quota_blocks => '4194304', :quota_files => '320000', :max_active_gears => '20',
         :max_active_apps => nil, :no_overcommit_active => true},
    ]

    scenarios.each do |scenario|
      @config.stubs(:get).with("GEAR_BASE_DIR", anything).returns('/var/lib/openshift')
      @config.stubs(:get).with("node_profile", anything).returns(scenario[:node_profile])
      @config.stubs(:get).with("quota_blocks", anything).returns(scenario[:quota_blocks])
      @config.stubs(:get).with("quota_files", anything).returns(scenario[:quota_files])
      @config.stubs(:get).with("max_active_gears", anything).returns(scenario[:max_active_gears])
      @config.stubs(:get).with("max_active_apps", anything).returns(scenario[:max_active_apps])
      @config.stubs(:get_bool).with("no_overcommit_active", anything).returns(scenario[:no_overcommit_active])
      OpenShift::Runtime::Node.stubs(:resource_limits).returns(@config)

      instance = mock()
      instance.stubs(:set_mcs_label).returns nil
      instance.stubs(:get_mcs_label).returns('s0:c0,c501')
      OpenShift::Runtime::Utils::SelinuxContext.stubs(:instance).returns(instance)

      appuids = (501...(501+ (scenario[:max_active_gears].nil? ? scenario[:max_active_apps].to_i : scenario[:max_active_gears].to_i)))

      apps = Array.new
      appuids.each do |uid|
        Etc.stubs(:getpwnam).returns(
          OpenStruct.new(
            uid:   uid,
            gid:   uid,
            gecos: "OpenShift guest",
            dir:   "/var/lib/openshift/#{uid}"
          )
        )

        app = OpenShift::Runtime::ApplicationContainer.new(uid.to_s, uid.to_s, uid, uid.to_s, uid.to_s, uid.to_s)
        FileUtils.mkdir_p(File.join(app.container_dir, "app-root", "runtime"))
        FileUtils.mkdir_p(PathUtils.join(app.container_dir, 'git', "#{app.application_name}.git"))
        app.state.value= 'started'
        apps << app
      end

      OpenShift::Runtime::ApplicationContainer.stubs(:all).returns(apps)

      node_utilization = OpenShift::Runtime::Node.node_utilization

      assert_equal scenario[:node_profile], node_utilization['node_profile']
      assert_equal scenario[:quota_blocks], node_utilization['quota_blocks']
      assert_equal scenario[:quota_files], node_utilization['quota_files']
      assert_equal scenario[:no_overcommit_active], node_utilization['no_overcommit_active']
      if scenario[:max_active_gears].nil?
        assert_equal scenario[:max_active_apps], node_utilization['max_active_gears']
      else
        assert_equal scenario[:max_active_gears], node_utilization['max_active_gears']
      end

      # All apps were created in a started state initially
      assert_equal apps.count, node_utilization['gears_total_count']
      assert_equal apps.count, node_utilization['gears_started_count']
      # assert_equal apps.count, node_utilization['git_repos_count']
      assert_equal apps.count, node_utilization['gears_active_count']
      assert_equal 0, node_utilization['gears_idled_count']
      assert_equal 0, node_utilization['gears_stopped_count']
      assert_equal 0, node_utilization['gears_deploying_count']
      assert_equal 0, node_utilization['gears_unknown_count']
      assert_equal 100.0, node_utilization['gears_usage_pct']
      assert_equal 100.0, node_utilization['gears_active_usage_pct']
      assert_equal "100.0", node_utilization['capacity']
      assert_equal "100.0", node_utilization['active_capacity']

      #idle a quarter of the apps
      apps.each_index do |idx|
        if idx < (apps.count / 4)
          apps[idx].state.value= 'idle'
        end
      end

      node_utilization = OpenShift::Runtime::Node.node_utilization
      assert_equal apps.count, node_utilization['gears_total_count']
      assert_equal (apps.count-apps.count/4), node_utilization['gears_started_count']
      # assert_equal apps.count, node_utilization['git_repos_count']
      assert_equal (apps.count-apps.count/4), node_utilization['gears_active_count']
      assert_equal apps.count/4, node_utilization['gears_idled_count']
      assert_equal 0, node_utilization['gears_stopped_count']
      assert_equal 0, node_utilization['gears_deploying_count']
      assert_equal 0, node_utilization['gears_unknown_count']
      assert_equal 100.0, node_utilization['gears_usage_pct']
      assert_equal 75.0, node_utilization['gears_active_usage_pct']
      assert_equal "100.0", node_utilization['capacity']
      assert_equal "75.0", node_utilization['active_capacity']

      #stop a quarter of the apps
      apps.each_index do |idx|
        if idx >= (apps.count / 4) and idx < (apps.count / 2)
          apps[idx].state.value= 'stopped'
        end
      end

      node_utilization = OpenShift::Runtime::Node.node_utilization
      assert_equal apps.count, node_utilization['gears_total_count']
      assert_equal apps.count/2, node_utilization['gears_started_count'] # 1/4 idled, 1/4 stopped
      # assert_equal apps.count, node_utilization['git_repos_count']
      assert_equal apps.count/2, node_utilization['gears_active_count'] # 1/4 idled, 1/4 stopped
      assert_equal apps.count/4, node_utilization['gears_idled_count']
      assert_equal apps.count/4, node_utilization['gears_stopped_count']
      assert_equal 0, node_utilization['gears_deploying_count']
      assert_equal 0, node_utilization['gears_unknown_count']
      assert_equal 100.0, node_utilization['gears_usage_pct']
      assert_equal 50.0, node_utilization['gears_active_usage_pct']
      assert_equal "100.0", node_utilization['capacity']
      assert_equal "50.0", node_utilization['active_capacity']

      #change 1/4 of the apps to each of the deploying states
      ['new', 'deploying', 'building'].each do |state|
        apps.each_index do |idx|
          if idx >= (apps.count / 2) and idx < (apps.count - apps.count / 4)
            apps[idx].state.value= state
          end
        end

        node_utilization = OpenShift::Runtime::Node.node_utilization
        assert_equal apps.count, node_utilization['gears_total_count']
        assert_equal apps.count/4, node_utilization['gears_started_count'] # 1/4 idled, 1/4 stopped, 1/4 deploying
        # assert_equal apps.count, node_utilization['git_repos_count']
        assert_equal apps.count/2, node_utilization['gears_active_count'] # 1/4 idled, 1/4 stopped, deploying counts as active
        assert_equal apps.count/4, node_utilization['gears_idled_count']
        assert_equal apps.count/4, node_utilization['gears_stopped_count']
        assert_equal apps.count/4, node_utilization['gears_deploying_count']
        assert_equal 0, node_utilization['gears_unknown_count']
        assert_equal 100.0, node_utilization['gears_usage_pct']
        assert_equal 50.0, node_utilization['gears_active_usage_pct']
        assert_equal "100.0", node_utilization['capacity']
        assert_equal "50.0", node_utilization['active_capacity']
      end

      #change 1/4 of the apps to unknown
      apps.each_index do |idx|
        if idx >= (apps.count - apps.count / 4) and idx < (apps.count)
          apps[idx].state.value= 'unknown'
        end
      end

      node_utilization = OpenShift::Runtime::Node.node_utilization
      assert_equal apps.count, node_utilization['gears_total_count']
      assert_equal 0, node_utilization['gears_started_count'] # 1/4 idled, 1/4 stopped, 1/4 deploying, 1/4 unknown
      # assert_equal apps.count, node_utilization['git_repos_count']
      assert_equal apps.count/2, node_utilization['gears_active_count'] # 1/4 idled, 1/4 stopped, deploying and unknown counts as active
      assert_equal apps.count/4, node_utilization['gears_idled_count']
      assert_equal apps.count/4, node_utilization['gears_stopped_count']
      assert_equal apps.count/4, node_utilization['gears_deploying_count']
      assert_equal apps.count/4, node_utilization['gears_unknown_count']
      assert_equal 100.0, node_utilization['gears_usage_pct']
      assert_equal 50.0, node_utilization['gears_active_usage_pct']
      assert_equal "100.0", node_utilization['capacity']
      assert_equal "50.0", node_utilization['active_capacity']


      # Remove half the apps (the deploying/unknown apps)
      apps = apps.first(apps.count/2)
      OpenShift::Runtime::ApplicationContainer.stubs(:all).returns(apps)

      node_utilization = OpenShift::Runtime::Node.node_utilization
      assert_equal apps.count, node_utilization['gears_total_count']
      assert_equal 0, node_utilization['gears_started_count'] # 1/2 idled, 1/2 stopped
      # assert_equal apps.count, node_utilization['git_repos_count']
      assert_equal 0, node_utilization['gears_active_count'] # 1/2 idled, 1/2 stopped
      assert_equal apps.count/2, node_utilization['gears_idled_count']
      assert_equal apps.count/2, node_utilization['gears_stopped_count']
      assert_equal 0, node_utilization['gears_deploying_count']
      assert_equal 0, node_utilization['gears_unknown_count']
      assert_equal 50.0, node_utilization['gears_usage_pct']
      assert_equal 0.0, node_utilization['gears_active_usage_pct']
      assert_equal "50.0", node_utilization['capacity']
      assert_equal "0.0", node_utilization['active_capacity']

      # Remove git repos from half of the remaining apps
      apps.each_index do |idx|
        if idx < apps.count / 2
          FileUtils.rm_rf(PathUtils.join(apps[idx].container_dir, 'git', "#{apps[idx].application_name}.git"))
        end
      end

      node_utilization = OpenShift::Runtime::Node.node_utilization
      assert_equal apps.count, node_utilization['gears_total_count']
      assert_equal 0, node_utilization['gears_started_count'] # 1/2 idled, 1/2 stopped
      # assert_equal apps.count/2, node_utilization['git_repos_count']
      assert_equal 0, node_utilization['gears_active_count'] # 1/2 idled, 1/2 stopped
      assert_equal apps.count/2, node_utilization['gears_idled_count']
      assert_equal apps.count/2, node_utilization['gears_stopped_count']
      assert_equal 0, node_utilization['gears_deploying_count']
      assert_equal 0, node_utilization['gears_unknown_count']
      assert_equal 50.0, node_utilization['gears_usage_pct']
      assert_equal 0.0, node_utilization['gears_active_usage_pct']
      assert_equal "50.0", node_utilization['capacity']
      assert_equal "0.0", node_utilization['active_capacity']

    end
  end
end
