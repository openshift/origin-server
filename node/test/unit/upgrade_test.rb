require_relative '../test_helper'
require_relative '../../lib/openshift-origin-node/model/upgrade'

module OpenShift
  module Runtime
    class UpgradeTest < ::OpenShift::NodeTestCase
      attr_reader :progress, :cart_model, :current_manifest, :current_version, :next_manifest, :version, :target, :container, :upgrader

      def setup
        @progress = mock()
        @progress.stubs(:log).with(kind_of(String), kind_of(Hash))
        @progress.stubs(:log).with(kind_of(String))
        @progress.stubs(:report)
        Utils::UpgradeProgress.expects(:new).at_most(2).returns(@progress)

        @cart_model = mock()

        @next_manifest = mock()
        @next_manifest.stubs(:short_name).returns('mock')
        @next_manifest.stubs(:name).returns('mock')
        @next_manifest.stubs(:cartridge_version).returns('0.0.2')

        @current_version = '0.0.1'

        @current_manifest = mock()
        @current_manifest.stubs(:short_name).returns('mock')
        @current_manifest.stubs(:name).returns('mock')
        @current_manifest.stubs(:directory).returns('current/shouldnotexist')
        @current_manifest.stubs(:cartridge_version).returns(current_version)

        @version = '1.1'
        @target = 'foo'

        @container = mock()
        @container.stubs(:uid).returns('123')
        @container.stubs(:gid).returns('456')
        @container.stubs(:uuid).returns('fairly_invalid')
        @container.stubs(:container_dir).returns('user/shouldnotexist')
        @container.stubs(:homedir).returns('user/shouldnotexist')

        @uuid = '123'
        @app_uuid = 'abc'

        @config.expects(:get).with('GEAR_BASE_DIR').at_most(2).returns('/test')

        @hourglass = mock()
        @hourglass.stubs(:remaining).returns(420)

        @gear_env = mock()
        Utils::Environ.expects(:for_gear).with('/test/123').at_most(2).returns(@gear_env)
        ApplicationContainer.expects(:from_uuid).with(@uuid, @hourglass).at_most(2).returns(@container)

        @upgrader = Upgrader.new(@uuid, @app_uuid, nil, nil, 'namespace', @version, 'hostname', false, @hourglass)
      end

      def test_compatible_success
        CartridgeRepository.expects(:overlay_cartridge).with(next_manifest, target)

        container.expects(:processed_templates).with(next_manifest).returns(%w(a b c))
        Dir.expects(:glob).with(PathUtils.join(target, 'env', '*.erb')).returns(%w(d e))
        FileUtils.expects(:rm_f).with(%w(a b c))
        FileUtils.expects(:rm_f).with(%w(d e))

        cart_model.expects(:unlock_gear).with(next_manifest).yields(next_manifest)
        cart_model.expects(:secure_cartridge).with('mock', container.uid, container.gid, target)

        upgrader.expects(:execute_cartridge_upgrade_script).with(target, current_version, next_manifest)

        upgrader.compatible_upgrade(cart_model, current_version, next_manifest, target)
      end

      def test_incompatible_success
        container.expects(:setup_rewritten).with(next_manifest).returns(%w(a b/))
        File.expects(:file?).with('a').returns(true)
        File.expects(:directory?).with('a').returns(false)
        FileUtils.expects(:rm).with('a')

        File.expects(:directory?).with('b/').returns(true)
        File.expects(:file?).with('b/').returns(false)
        FileUtils.expects(:rm_r).with('b/')

        CartridgeRepository.expects(:overlay_cartridge).with(next_manifest, target)

        cart_model.expects(:unlock_gear).with(next_manifest).yields(next_manifest)
        cart_model.expects(:secure_cartridge).with('mock', container.uid, container.gid, target)

        progress.expects(:step).with('mock_setup').yields({}, [])
        cart_model.expects(:cartridge_action).with(next_manifest, 'setup', version, true).returns('yay')

        progress.expects(:step).with('mock_erb').yields({}, [])
        cart_model.expects(:process_erb_templates).with(next_manifest)

        progress.expects(:step).with('mock_create_endpoints').yields({}, [])
        cart_model.expects(:create_private_endpoints).with(next_manifest)

        progress.expects(:step).with('mock_connect_frontend').yields({}, [])
        cart_model.expects(:connect_frontend).with(next_manifest)

        upgrader.expects(:execute_cartridge_upgrade_script).with(target, current_version, next_manifest)

        upgrader.incompatible_upgrade(cart_model, current_version, next_manifest, version, target)
      end

      def test_incompatible_recover_after_setup
        container.expects(:setup_rewritten).with(next_manifest).returns(%w(a b/))
        File.expects(:file?).with('a').returns(true)
        File.expects(:directory?).with('a').returns(false)
        FileUtils.expects(:rm).with('a')

        File.expects(:directory?).with('b/').returns(true)
        File.expects(:file?).with('b/').returns(false)
        FileUtils.expects(:rm_r).with('b/')

        CartridgeRepository.expects(:overlay_cartridge).with(next_manifest, target)

        cart_model.expects(:unlock_gear).with(next_manifest).yields(next_manifest)
        cart_model.expects(:secure_cartridge).with('mock', container.uid, container.gid, target)

        progress.expects(:step).with('mock_setup')
        cart_model.expects(:cartridge_action).never()

        progress.expects(:step).with('mock_erb').yields({}, [])
        cart_model.expects(:process_erb_templates).with(next_manifest)

        progress.expects(:step).with('mock_create_endpoints').yields({}, [])
        cart_model.expects(:create_private_endpoints).with(next_manifest)

        progress.expects(:step).with('mock_connect_frontend').yields({}, [])
        cart_model.expects(:connect_frontend).with(next_manifest)

        upgrader.expects(:execute_cartridge_upgrade_script).with(target, current_version, next_manifest)

        upgrader.incompatible_upgrade(cart_model, current_version, next_manifest, version, target)
      end

      def test_incompatible_recover_after_erb_processing
        container.expects(:setup_rewritten).with(next_manifest).returns(%w(a b/))
        File.expects(:file?).with('a').returns(true)
        File.expects(:directory?).with('a').returns(false)
        FileUtils.expects(:rm).with('a')

        File.expects(:directory?).with('b/').returns(true)
        File.expects(:file?).with('b/').returns(false)
        FileUtils.expects(:rm_r).with('b/')

        CartridgeRepository.expects(:overlay_cartridge).with(next_manifest, target)

        cart_model.expects(:unlock_gear).with(next_manifest).yields(next_manifest)
        cart_model.expects(:secure_cartridge).with('mock', container.uid, container.gid, target)

        progress.expects(:step).with('mock_setup')
        cart_model.expects(:cartridge_action).never()

        progress.expects(:step).with('mock_erb')
        cart_model.expects(:process_erb_templates).never()

        progress.expects(:step).with('mock_create_endpoints').yields({}, [])
        cart_model.expects(:create_private_endpoints).with(next_manifest)

        progress.expects(:step).with('mock_connect_frontend').yields({}, [])
        cart_model.expects(:connect_frontend).with(next_manifest)

        upgrader.expects(:execute_cartridge_upgrade_script).with(target, current_version, next_manifest)

        upgrader.incompatible_upgrade(cart_model, current_version, next_manifest, version, target)
      end

      def test_incompatible_done
        container.expects(:setup_rewritten).with(next_manifest).returns(%w(a b/))
        File.expects(:file?).with('a').returns(true)
        File.expects(:directory?).with('a').returns(false)
        FileUtils.expects(:rm).with('a')

        File.expects(:directory?).with('b/').returns(true)
        File.expects(:file?).with('b/').returns(false)
        FileUtils.expects(:rm_r).with('b/')

        CartridgeRepository.expects(:overlay_cartridge).with(next_manifest, target)

        cart_model.expects(:unlock_gear).with(next_manifest).yields(next_manifest)
        cart_model.expects(:secure_cartridge).with('mock', container.uid, container.gid, target)

        progress.expects(:step).with('mock_setup')
        cart_model.expects(:cartridge_action).never()

        progress.expects(:step).with('mock_erb')
        cart_model.expects(:process_erb_templates).never()

        progress.expects(:step).with('mock_create_endpoints')
        cart_model.expects(:create_private_endpoints).never()

        progress.expects(:step).with('mock_connect_frontend')
        cart_model.expects(:connect_frontend).never()

        upgrader.expects(:execute_cartridge_upgrade_script).with(target, current_version, next_manifest)

        upgrader.incompatible_upgrade(cart_model, current_version, next_manifest, version, target)
      end

      def test_gear_pre_upgrade
        gear_extension = mock()
        gear_extension.expects(:pre_upgrade).with(progress)
        gear_extension.stubs(:respond_to?).with(:pre_upgrade).returns(true)
        gear_extension.stubs(:nil?).returns(false)
        upgrader.stubs(:gear_extension).returns(gear_extension)
        progress.expects(:step).with('pre_upgrade').yields({}, [])

        upgrader.gear_pre_upgrade
      end

      def test_gear_pre_upgrade_without_implementation
        gear_extension = mock()
        gear_extension.expects(:pre_upgrade).never
        gear_extension.stubs(:respond_to?).with(:pre_upgrade).returns(false)
        gear_extension.stubs(:nil?).returns(false)
        upgrader.stubs(:gear_extension).returns(gear_extension)
        progress.expects(:step).with('pre_upgrade').never

        upgrader.gear_pre_upgrade
      end

      def test_gear_pre_upgrade_without_gear_extension
        gear_extension = mock()
        gear_extension.expects(:pre_upgrade).never
        gear_extension.stubs(:respond_to?).with(:pre_upgrade).returns(false)
        gear_extension.stubs(:nil?).returns(true)
        upgrader.stubs(:gear_extension).returns(gear_extension)
        progress.expects(:step).with('pre_upgrade').never

        upgrader.gear_pre_upgrade
      end

      def test_gear_post_upgrade
        gear_extension = mock()
        gear_extension.expects(:post_upgrade).with(progress)
        gear_extension.stubs(:respond_to?).with(:post_upgrade).returns(true)
        gear_extension.stubs(:nil?).returns(false)
        upgrader.stubs(:gear_extension).returns(gear_extension)
        progress.expects(:step).with('post_upgrade').yields({}, [])

        upgrader.gear_post_upgrade
      end

      def test_gear_post_upgrade_without_implementation
        gear_extension = mock()
        gear_extension.expects(:post_upgrade).never
        gear_extension.stubs(:respond_to?).with(:post_upgrade).returns(false)
        gear_extension.stubs(:nil?).returns(false)
        upgrader.stubs(:gear_extension).returns(gear_extension)
        progress.expects(:step).with('post_upgrade').never

        upgrader.gear_post_upgrade
      end

      def test_gear_post_upgrade_without_gear_extension
        gear_extension = mock()
        gear_extension.expects(:post_upgrade).never
        gear_extension.stubs(:respond_to?).with(:post_upgrade).returns(false)
        gear_extension.stubs(:nil?).returns(true)
        upgrader.stubs(:gear_extension).returns(gear_extension)
        progress.expects(:step).with('post_upgrade').never

        upgrader.gear_post_upgrade
      end

      def test_gear_map_ident
        gear_extension = mock()
        gear_extension.expects(:map_ident).with(progress, 'test')
        gear_extension.stubs(:respond_to?).with(:map_ident).returns(true)
        gear_extension.stubs(:nil?).returns(false)
        upgrader.stubs(:gear_extension).returns(gear_extension)

        upgrader.gear_map_ident('test')
      end

      def test_gear_map_ident_without_implementation
        OpenShift::Runtime::Manifest.expects(:parse_ident).with('test')
        gear_extension = mock()
        gear_extension.expects(:map_ident).never
        gear_extension.stubs(:respond_to?).with(:map_ident).returns(false)
        gear_extension.stubs(:nil?).returns(false)
        upgrader.stubs(:gear_extension).returns(gear_extension)

        upgrader.gear_map_ident('test')
      end

      def test_gear_map_ident_without_gear_extension
        OpenShift::Runtime::Manifest.expects(:parse_ident).with('test')
        gear_extension = mock()
        gear_extension.expects(:map_ident).never
        gear_extension.stubs(:respond_to?).with(:map_ident).returns(false)
        gear_extension.stubs(:nil?).returns(true)
        upgrader.stubs(:gear_extension).returns(gear_extension)

        upgrader.gear_map_ident('test')
      end

      def test_compatible_compute_itinerary
        cartridge_model                   = mock()
        cartridge_repository              = mock()
        itinerary                         = mock()
        manifest                          = mock()
        next_manifest                     = mock()
        next_manifest_versions            = mock()
        next_manifest_compatible_versions = mock()
        state                             = mock()

        cartridge_model.expects(:each_cartridge).yields(manifest)

        cartridge_repository.expects(:select).with('test', '0.1').returns(next_manifest)

        itinerary.expects(:create_entry).with('test-0.1', 'compatible')
        itinerary.expects(:persist)
        manifest.expects(:directory).returns('test')

        next_manifest.expects(:versions).returns(next_manifest_versions)
        next_manifest.expects(:compatible_versions).returns(next_manifest_compatible_versions)
        next_manifest.expects(:cartridge_version).returns('0.0.2')

        next_manifest_versions.expects(:include?).with('0.1').returns(true)

        next_manifest_compatible_versions.expects(:include?).with('0.0.1').returns(true)

        progress.expects(:step).with('compute_itinerary').yields({}, [])

        IO.expects(:read).with(nil).returns('redhat:test:0.1:0.0.1')

        File.expects(:directory?).with('/test/123/test').returns(true)

        OpenShift::Runtime::CartridgeRepository.expects(:instance).returns(cartridge_repository)
        OpenShift::Runtime::UpgradeItinerary.expects(:for_gear).with('/test/123')
        OpenShift::Runtime::UpgradeItinerary.expects(:new).with('/test/123').returns(itinerary)
        OpenShift::Runtime::Utils::ApplicationState.expects(:new).with(@container).returns(state)
        OpenShift::Runtime::V2UpgradeCartridgeModel.expects(:new).with(@config,
                                                                       @container,
                                                                       state,
                                                                       @hourglass).returns(cartridge_model)
        upgrader.compute_itinerary
      end

      def test_incompatible_compute_itinerary
        cartridge_model                   = mock()
        cartridge_repository              = mock()
        itinerary                         = mock()
        manifest                          = mock()
        next_manifest                     = mock()
        next_manifest_versions            = mock()
        next_manifest_compatible_versions = mock()
        state                             = mock()

        cartridge_model.expects(:each_cartridge).yields(manifest)

        cartridge_repository.expects(:select).with('test', '0.1').returns(next_manifest)

        itinerary.expects(:create_entry).with('test-0.1', 'incompatible')
        itinerary.expects(:persist)
        manifest.expects(:directory).returns('test')

        next_manifest.expects(:versions).returns(next_manifest_versions)
        next_manifest.expects(:compatible_versions).returns(next_manifest_compatible_versions)
        next_manifest.expects(:cartridge_version).returns('0.0.2')

        next_manifest_versions.expects(:include?).with('0.1').returns(true)

        next_manifest_compatible_versions.expects(:include?).with('0.0.1').returns(false)

        progress.expects(:step).with('compute_itinerary').yields({}, [])

        IO.expects(:read).with(nil).returns('redhat:test:0.1:0.0.1')

        File.expects(:directory?).with('/test/123/test').returns(true)

        OpenShift::Runtime::CartridgeRepository.expects(:instance).returns(cartridge_repository)
        OpenShift::Runtime::UpgradeItinerary.expects(:for_gear).with('/test/123')
        OpenShift::Runtime::UpgradeItinerary.expects(:new).with('/test/123').returns(itinerary)
        OpenShift::Runtime::Utils::ApplicationState.expects(:new).with(@container).returns(state)
        OpenShift::Runtime::V2UpgradeCartridgeModel.expects(:new).with(@config,
                                                                       @container,
                                                                       state,
                                                                       @hourglass).returns(cartridge_model)
        upgrader.compute_itinerary
      end

      def test_compute_itinerary_at_latest_version_ignore_cart_version
        cartridge_model                   = mock()
        cartridge_repository              = mock()
        itinerary                         = mock()
        manifest                          = mock()
        next_manifest                     = mock()
        next_manifest_versions            = mock()
        next_manifest_compatible_versions = mock()
        state                             = mock()

        icv_upgrader = Upgrader.new(@uuid, 'namespace', @version, 'hostname', true, @hourglass)
        cartridge_model.expects(:each_cartridge).yields(manifest)

        cartridge_repository.expects(:select).with('test', '0.1').returns(next_manifest)

        itinerary.expects(:create_entry).with('test-0.1', 'incompatible')
        itinerary.expects(:persist)
        manifest.expects(:directory).returns('test')

        next_manifest.expects(:versions).returns(next_manifest_versions)
        next_manifest.expects(:compatible_versions).returns(next_manifest_compatible_versions)
        next_manifest.expects(:cartridge_version).returns('0.0.1')

        next_manifest_versions.expects(:include?).with('0.1').returns(true)

        next_manifest_compatible_versions.expects(:include?).with('0.0.1').returns(false)

        progress.expects(:step).with('compute_itinerary').yields({}, [])

        IO.expects(:read).with(nil).returns('redhat:test:0.1:0.0.1')

        File.expects(:directory?).with('/test/123/test').returns(true)

        OpenShift::Runtime::CartridgeRepository.expects(:instance).returns(cartridge_repository)
        OpenShift::Runtime::UpgradeItinerary.expects(:for_gear).with('/test/123')
        OpenShift::Runtime::UpgradeItinerary.expects(:new).with('/test/123').returns(itinerary)
        OpenShift::Runtime::Utils::ApplicationState.expects(:new).with(@container).returns(state)
        OpenShift::Runtime::V2UpgradeCartridgeModel.expects(:new).with(@config,
                                                                       @container,
                                                                       state,
                                                                       @hourglass).returns(cartridge_model)
        icv_upgrader.compute_itinerary
      end

      def test_compute_itinerary_invalid_cart_path
        cartridge_model                   = mock()
        cartridge_repository              = mock()
        itinerary                         = mock()
        manifest                          = mock()
        state                             = mock()

        cartridge_model.expects(:each_cartridge).yields(manifest)

        cartridge_repository.expects(:select).never

        itinerary.expects(:persist)
        itinerary.expects(:create_entry).never
        manifest.expects(:directory).returns('test')
        manifest.expects(:name).once.returns('test')

        progress.expects(:step).with('compute_itinerary').yields({}, [])

        IO.expects(:read).with(nil).never
        upgrader.expects(:gear_map_ident).never

        File.expects(:directory?).with('/test/123/test').returns(false)

        OpenShift::Runtime::CartridgeRepository.expects(:instance).returns(cartridge_repository)
        OpenShift::Runtime::UpgradeItinerary.expects(:for_gear).with('/test/123')
        OpenShift::Runtime::UpgradeItinerary.expects(:new).with('/test/123').returns(itinerary)
        OpenShift::Runtime::Utils::ApplicationState.expects(:new).with(@container).returns(state)
        OpenShift::Runtime::V2UpgradeCartridgeModel.expects(:new).with(@config,
                                                                       @container,
                                                                       state,
                                                                       @hourglass).returns(cartridge_model)
        upgrader.compute_itinerary
      end

      def test_compute_itinerary_unsupported_vendor
        cartridge_model                   = mock()
        cartridge_repository              = mock()
        itinerary                         = mock()
        manifest                          = mock()
        state                             = mock()

        cartridge_model.expects(:each_cartridge).yields(manifest)

        itinerary.expects(:persist)
        itinerary.expects(:create_entry).never
        manifest.expects(:directory).returns('test')

        progress.expects(:step).with('compute_itinerary').yields({}, [])

        IO.expects(:read).with(nil).returns('scary_monkey_co:test:0.1:0.0.1')

        File.expects(:directory?).with('/test/123/test').returns(true)

        OpenShift::Runtime::CartridgeRepository.expects(:instance).returns(cartridge_repository)
        OpenShift::Runtime::UpgradeItinerary.expects(:for_gear).with('/test/123')
        OpenShift::Runtime::UpgradeItinerary.expects(:new).with('/test/123').returns(itinerary)
        OpenShift::Runtime::Utils::ApplicationState.expects(:new).with(@container).returns(state)
        OpenShift::Runtime::V2UpgradeCartridgeModel.expects(:new).with(@config,
                                                                       @container,
                                                                       state,
                                                                       @hourglass).returns(cartridge_model)
        upgrader.compute_itinerary
      end

      def test_compute_itinerary_cartridge_not_found
        cartridge_model                   = mock()
        cartridge_repository              = mock()
        itinerary                         = mock()
        manifest                          = mock()
        state                             = mock()

        cartridge_model.expects(:each_cartridge).yields(manifest)

        cartridge_repository.expects(:select).with('test', '0.1').returns(false)

        itinerary.expects(:persist)
        itinerary.expects(:create_entry).never
        manifest.expects(:directory).returns('test')

        progress.expects(:step).with('compute_itinerary').yields({}, [])

        IO.expects(:read).with(nil).returns('redhat:test:0.1:0.0.1')

        File.expects(:directory?).with('/test/123/test').returns(true)

        OpenShift::Runtime::CartridgeRepository.expects(:instance).returns(cartridge_repository)
        OpenShift::Runtime::UpgradeItinerary.expects(:for_gear).with('/test/123')
        OpenShift::Runtime::UpgradeItinerary.expects(:new).with('/test/123').returns(itinerary)
        OpenShift::Runtime::Utils::ApplicationState.expects(:new).with(@container).returns(state)
        OpenShift::Runtime::V2UpgradeCartridgeModel.expects(:new).with(@config,
                                                                       @container,
                                                                       state,
                                                                       @hourglass).returns(cartridge_model)
        upgrader.compute_itinerary
      end

      def test_compute_itinerary_version_not_found
        cartridge_model                   = mock()
        cartridge_repository              = mock()
        itinerary                         = mock()
        manifest                          = mock()
        next_manifest                     = mock()
        next_manifest_versions            = mock()
        state                             = mock()

        cartridge_model.expects(:each_cartridge).yields(manifest)

        cartridge_repository.expects(:select).with('test', '0.1').returns(next_manifest)

        itinerary.expects(:persist)
        itinerary.expects(:create_entry).never
        manifest.expects(:directory).returns('test')

        next_manifest.expects(:versions).at_most(2).returns(['0.2'])
        next_manifest.expects(:cartridge_version).never
        next_manifest.expects(:compatible_versions).never

        progress.expects(:step).with('compute_itinerary').yields({}, [])

        IO.expects(:read).with(nil).returns('redhat:test:0.1:0.0.1')

        File.expects(:directory?).with('/test/123/test').returns(true)

        OpenShift::Runtime::CartridgeRepository.expects(:instance).returns(cartridge_repository)
        OpenShift::Runtime::UpgradeItinerary.expects(:for_gear).with('/test/123')
        OpenShift::Runtime::UpgradeItinerary.expects(:new).with('/test/123').returns(itinerary)
        OpenShift::Runtime::Utils::ApplicationState.expects(:new).with(@container).returns(state)
        OpenShift::Runtime::V2UpgradeCartridgeModel.expects(:new).with(@config,
                                                                       @container,
                                                                       state,
                                                                       @hourglass).returns(cartridge_model)
        upgrader.compute_itinerary
      end

      def test_compute_itinerary_at_latest_version
        cartridge_model                   = mock()
        cartridge_repository              = mock()
        itinerary                         = mock()
        manifest                          = mock()
        next_manifest                     = mock()
        next_manifest_versions            = mock()
        state                             = mock()

        cartridge_model.expects(:each_cartridge).yields(manifest)

        cartridge_repository.expects(:select).with('test', '0.1').returns(next_manifest)

        itinerary.expects(:create_entry).never
        itinerary.expects(:persist)
        manifest.expects(:directory).returns('test')

        next_manifest.expects(:versions).returns(next_manifest_versions)
        next_manifest.expects(:compatible_versions).never
        next_manifest.expects(:cartridge_version).returns('0.0.1')

        next_manifest_versions.expects(:include?).with('0.1').returns(true)

        progress.expects(:step).with('compute_itinerary').yields({}, [])

        IO.expects(:read).with(nil).returns('redhat:test:0.1:0.0.1')

        File.expects(:directory?).with('/test/123/test').returns(true)

        OpenShift::Runtime::CartridgeRepository.expects(:instance).returns(cartridge_repository)
        OpenShift::Runtime::UpgradeItinerary.expects(:for_gear).with('/test/123')
        OpenShift::Runtime::UpgradeItinerary.expects(:new).with('/test/123').returns(itinerary)
        OpenShift::Runtime::Utils::ApplicationState.expects(:new).with(@container).returns(state)
        OpenShift::Runtime::V2UpgradeCartridgeModel.expects(:new).with(@config,
                                                                       @container,
                                                                       state,
                                                                       @hourglass).returns(cartridge_model)
        upgrader.compute_itinerary
      end

    end
  end
end
