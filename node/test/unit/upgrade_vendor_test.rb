require_relative '../test_helper'
require_relative '../../lib/openshift-origin-node/model/upgrade'

require 'fakefs/safe'

module OpenShift
  module Runtime
    class UpgradeVendorTest < ::OpenShift::NodeTestCase
      attr_reader :progress, :current_manifest, :current_version, :gear_home, :itinerary, :next_manifest, :version, :container, :upgrader

      def setup
        FakeFS.activate!
        FakeFS::FileSystem.clear

        @next_manifest = mock()
        @next_manifest.stubs(:short_name).returns('mock')
        @next_manifest.stubs(:name).returns('mock')
        @next_manifest.stubs(:cartridge_version).returns('0.0.2')
        @next_manifest.stubs(:cartridge_vendor).returns('mockvendor')
        @next_manifest.stubs(:compatible_versions).returns(["0.1", "0.2"])
        @next_manifest.stubs(:versions).returns(["0.1", "0.2"])

        @current_version = '0.0.1'

        @current_manifest = mock()
        @current_manifest.stubs(:short_name).returns('mock')
        @current_manifest.stubs(:name).returns('mock')
        @current_manifest.stubs(:directory).returns('current/shouldnotexist')
        @current_manifest.stubs(:cartridge_version).returns(current_version)

        @version = '1.1'

        @container = mock()
        @container.stubs(:uid).returns('123')
        @container.stubs(:uuid).returns('deadbeef')
        @container.stubs(:gid).returns('456')
        @container.stubs(:homedir).returns('user/shouldnotexist')
        @container.stubs(:container_dir).returns('/test/123')

        @uuid = '123'
        @app_uuid = 'abc'

        @config.stubs(:get).with('GEAR_BASE_DIR').returns('/test')

        gear_base_dir = @config.get('GEAR_BASE_DIR')
        @gear_home = PathUtils.join(gear_base_dir, @uuid)
        @progress = Utils::UpgradeProgress.new(gear_base_dir, @gear_home, @uuid)
        @progress.stubs(:log).with(kind_of(String))
        @progress.stubs(:report)
        @progress.stubs(:mark_complete)
        @progress.stubs(:incomplete?).with('compute_itinerary').returns(true)
        Utils::UpgradeProgress.expects(:new).returns(@progress)

        @hourglass = mock()
        @gear_env = mock()
        Utils::Environ.expects(:for_gear).with('/test/123').returns(@gear_env)
        ApplicationContainer.expects(:from_uuid).with(@uuid, @hourglass).returns(@container)

        @itinerary = mock()
        @itinerary.stubs(:persist)

        @upgrader = Upgrader.new(@uuid, @app_uuid, 'namespace', @version, 'hostname', false, false, @hourglass)
      end

      def teardown
        FakeFS.deactivate!
      end

      def test_non_redhat_vendor_that_exists_in_cartridge_repository
        env_path = "/test/123/current/shouldnotexist/env"
        FileUtils.mkpath(env_path)
        File.open("#{env_path}/OPENSHIFT_MOCK_IDENT", 'w')

        upgrader.expects(:gear_map_ident).returns(['mockvendor', 'mockname', '0.1', '0.0.1'])
        upgrader.expects(:compute_endpoints_upgrade_data).returns("mock_endpoint_data")
        progress.expects(:log).with(regexp_matches(/No upgrade available for cartridge/)).never
        OpenShift::Runtime::UpgradeItinerary.expects(:new).with(gear_home).returns(itinerary)
        OpenShift::Runtime::UpgradeItinerary.expects(:for_gear).with(gear_home)

        cartridge_model = mock()
        cartridge_model.expects(:each_cartridge).yields(current_manifest)
        OpenShift::Runtime::V2UpgradeCartridgeModel.stubs(:new).returns(cartridge_model)
        OpenShift::Runtime::CartridgeRepository.any_instance.stubs(:select).returns(next_manifest)

        itinerary.expects(:create_entry).with('mockname-0.1', 'incompatible', 'mock_endpoint_data')

        upgrader.compute_itinerary
      end

      def test_vendor_no_in_cartridge_repository
        env_path = "/test/123/current/shouldnotexist/env"
        FileUtils.mkpath(env_path)
        File.open("#{env_path}/OPENSHIFT_MOCK_IDENT", 'w')

        upgrader.expects(:gear_map_ident).returns(['vendor_that_doesnt_match', 'mockname', '0.1', '0.0.1'])
        progress.expects(:log).with(regexp_matches(/cartridge not found in repository/))
        OpenShift::Runtime::UpgradeItinerary.expects(:new).with(gear_home).returns(itinerary)
        OpenShift::Runtime::UpgradeItinerary.expects(:for_gear).with(gear_home)

        cartridge_model = mock()
        cartridge_model.expects(:each_cartridge).yields(current_manifest)
        OpenShift::Runtime::V2UpgradeCartridgeModel.stubs(:new).returns(cartridge_model)

        upgrader.compute_itinerary
      end
    end
  end
end
