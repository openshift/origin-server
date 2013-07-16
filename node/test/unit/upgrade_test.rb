require_relative '../test_helper'
require_relative '../../lib/openshift-origin-node/model/upgrade'

module OpenShift
  module Runtime
    class UpgradeTest < ::OpenShift::NodeTestCase
      attr_reader :progress, :cart_model, :current_manifest, :current_version, :next_manifest, :version, :target, :container, :upgrader

      def setup
        @progress = mock()
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
        @target = mock()

        @container = mock()
        @container.stubs(:uid).returns('123')
        @container.stubs(:gid).returns('456')
        @container.stubs(:homedir).returns('user/shouldnotexist')

        @uuid = '123'

        @config = mock()
        @config.expects(:get).with('GEAR_BASE_DIR').returns('/test')

        @gear_env = mock()
        Utils::Environ.expects(:for_gear).with('/test/123').returns(@gear_env)

        OpenShift::Config.expects(:new).returns(@config)
        ApplicationContainer.expects(:from_uuid).with(@uuid).returns(@container)

        @upgrader = Upgrader.new(@uuid, 'namespace', @version, 'hostname', false)
      end

      def test_compatible_success
        CartridgeRepository.expects(:overlay_cartridge).with(next_manifest, target)

        container.expects(:processed_templates).with(next_manifest).returns(%w(a b c))
        FileUtils.expects(:rm_f).with(%w(a b c))
        
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

        progress.expects(:incomplete?).with('mock_setup').returns(true)
        cart_model.expects(:cartridge_action).with(next_manifest, 'setup', version, true).returns('yay')
        progress.expects(:mark_complete).with('mock_setup')

        progress.expects(:incomplete?).with('mock_erb').returns(true)
        cart_model.expects(:process_erb_templates).with(next_manifest)
        progress.expects(:mark_complete).with('mock_erb')

        progress.expects(:incomplete?).with('mock_connect_frontend').returns(true)
        cart_model.expects(:connect_frontend).with(next_manifest)
        progress.expects(:mark_complete).with('mock_connect_frontend')

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

        progress.expects(:incomplete?).with('mock_setup').returns(false)
        cart_model.expects(:cartridge_action).never()

        progress.expects(:incomplete?).with('mock_erb').returns(true)
        cart_model.expects(:process_erb_templates).with(next_manifest)
        progress.expects(:mark_complete).with('mock_erb')

        progress.expects(:incomplete?).with('mock_connect_frontend').returns(true)
        cart_model.expects(:connect_frontend).with(next_manifest)
        progress.expects(:mark_complete).with('mock_connect_frontend')

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

        progress.expects(:incomplete?).with('mock_setup').returns(false)
        cart_model.expects(:cartridge_action).never()

        progress.expects(:incomplete?).with('mock_erb').returns(false)
        cart_model.expects(:process_erb_templates).never()

        progress.expects(:incomplete?).with('mock_connect_frontend').returns(true)
        cart_model.expects(:connect_frontend).with(next_manifest)
        progress.expects(:mark_complete).with('mock_connect_frontend')

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

        progress.expects(:incomplete?).with('mock_setup').returns(false)
        cart_model.expects(:cartridge_action).never()

        progress.expects(:incomplete?).with('mock_erb').returns(false)
        cart_model.expects(:process_erb_templates).never()

        progress.expects(:incomplete?).with('mock_connect_frontend').returns(false)
        cart_model.expects(:connect_frontend).never()

        upgrader.expects(:execute_cartridge_upgrade_script).with(target, current_version, next_manifest)

        upgrader.incompatible_upgrade(cart_model, current_version, next_manifest, version, target)
      end

    end
  end
end
