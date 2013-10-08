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
        Utils::UpgradeProgress.expects(:new).returns(@progress)

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
        @container.stubs(:homedir).returns('user/shouldnotexist')

        @uuid = '123'
        @app_uuid = 'abc'

        @config.expects(:get).with('GEAR_BASE_DIR').returns('/test')

        @hourglass = mock()
        @hourglass.stubs(:remaining).returns(420)

        @gear_env = mock()
        Utils::Environ.expects(:for_gear).with('/test/123').returns(@gear_env)
        ApplicationContainer.expects(:from_uuid).with(@uuid, @hourglass).returns(@container)

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

    end
  end
end
