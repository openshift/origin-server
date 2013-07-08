require_relative '../test_helper'
require_relative '../../lib/openshift-origin-node/model/upgrade'

module OpenShift
  module Runtime
    class MigrationTest < ::OpenShift::NodeTestCase
      attr_reader :progress, :cart_model, :current_manifest, :next_manifest, :version, :target, :user

      def setup
        @progress = mock()
        @progress.stubs(:log).with(kind_of(String))
        @progress.stubs(:report)

        @cart_model = mock()

        @next_manifest = mock()
        @next_manifest.stubs(:short_name).returns('mock')
        @next_manifest.stubs(:name).returns('mock')

        @current_manifest = mock()
        @current_manifest.stubs(:short_name).returns('mock')
        @current_manifest.stubs(:name).returns('mock')
        @current_manifest.stubs(:directory).returns('current/shouldnotexist')

        @version = '1.1'
        @target = mock()

        @user = mock()
        @user.stubs(:uid).returns('123')
        @user.stubs(:gid).returns('456')
        @user.stubs(:homedir).returns('user/shouldnotexist')
      end

      # def test_cartridges_non_redhat
      #   uuid = '123'

      #   config = mock()
      #   OpenShift::Config.expects(:new).returns(config)

      #   state = mock()
      #   OpenShift::Util::ApplicationState.expects(:new).with(uuid).returns(state)

      #   OpenShift::UnixUser.expects(:from_uuid).with(uuid).returns(user)

      #   model = mock()
      #   OpenShift::V2MigrationCartridgeModel.expects(:new).with(config, user, state).returns(model)

      #   cartridge_repo = mock()
      #   OpenShift::CartridgeRepository.expects(:instance).returns(cartridge_repo)

      #   OpenShift::Runtime::Utils::Cgroups.expects(:with_no_cpu_limits).yields
      #   Dir.expects(:chdir).with(user.homedir).yields
      #   model.expects(:each_cartridge).yields(current_manifest)
        
      # end

      def test_compatible_success
        CartridgeRepository.expects(:overlay_cartridge).with(next_manifest, target)

        cart_model.expects(:processed_templates).with(next_manifest).returns(%w(a b c))
        FileUtils.expects(:rm_f).with(%w(a b c))
        
        cart_model.expects(:unlock_gear).with(next_manifest).yields(next_manifest)
        cart_model.expects(:secure_cartridge).with('mock', user.uid, user.gid, target)

        ::OpenShift::Runtime::Upgrade.compatible_upgrade(progress, cart_model, next_manifest, target, user)
      end

      def test_incompatible_success
        cart_model.expects(:setup_rewritten).with(next_manifest).returns(%w(a b/))
        File.expects(:file?).with('a').returns(true)
        File.expects(:directory?).with('a').returns(false)
        FileUtils.expects(:rm).with('a')

        File.expects(:directory?).with('b/').returns(true)
        File.expects(:file?).with('b/').returns(false)
        FileUtils.expects(:rm_r).with('b/')

        CartridgeRepository.expects(:overlay_cartridge).with(next_manifest, target)

        cart_model.expects(:unlock_gear).with(next_manifest).yields(next_manifest)
        cart_model.expects(:secure_cartridge).with('mock', user.uid, user.gid, target)

        progress.expects(:incomplete?).with('mock_setup').returns(true)
        cart_model.expects(:cartridge_action).with(next_manifest, 'setup', version, true).returns('yay')
        progress.expects(:mark_complete).with('mock_setup')

        progress.expects(:incomplete?).with('mock_erb').returns(true)
        cart_model.expects(:process_erb_templates).with(next_manifest)
        progress.expects(:mark_complete).with('mock_erb')

        progress.expects(:incomplete?).with('mock_connect_frontend').returns(true)
        cart_model.expects(:connect_frontend).with(next_manifest)
        progress.expects(:mark_complete).with('mock_connect_frontend')

        ::OpenShift::Runtime::Upgrade.incompatible_upgrade(progress, cart_model, next_manifest, version, target, user)
      end

      def test_incompatible_recover_after_setup
        cart_model.expects(:setup_rewritten).with(next_manifest).returns(%w(a b/))
        File.expects(:file?).with('a').returns(true)
        File.expects(:directory?).with('a').returns(false)
        FileUtils.expects(:rm).with('a')

        File.expects(:directory?).with('b/').returns(true)
        File.expects(:file?).with('b/').returns(false)
        FileUtils.expects(:rm_r).with('b/')

        CartridgeRepository.expects(:overlay_cartridge).with(next_manifest, target)

        cart_model.expects(:unlock_gear).with(next_manifest).yields(next_manifest)
        cart_model.expects(:secure_cartridge).with('mock', user.uid, user.gid, target)

        progress.expects(:incomplete?).with('mock_setup').returns(false)
        cart_model.expects(:cartridge_action).never()

        progress.expects(:incomplete?).with('mock_erb').returns(true)
        cart_model.expects(:process_erb_templates).with(next_manifest)
        progress.expects(:mark_complete).with('mock_erb')

        progress.expects(:incomplete?).with('mock_connect_frontend').returns(true)
        cart_model.expects(:connect_frontend).with(next_manifest)
        progress.expects(:mark_complete).with('mock_connect_frontend')

        ::OpenShift::Runtime::Upgrade.incompatible_upgrade(progress, cart_model, next_manifest, version, target, user)
      end

      def test_incompatible_recover_after_erb_processing
        cart_model.expects(:setup_rewritten).with(next_manifest).returns(%w(a b/))
        File.expects(:file?).with('a').returns(true)
        File.expects(:directory?).with('a').returns(false)
        FileUtils.expects(:rm).with('a')

        File.expects(:directory?).with('b/').returns(true)
        File.expects(:file?).with('b/').returns(false)
        FileUtils.expects(:rm_r).with('b/')

        CartridgeRepository.expects(:overlay_cartridge).with(next_manifest, target)

        cart_model.expects(:unlock_gear).with(next_manifest).yields(next_manifest)
        cart_model.expects(:secure_cartridge).with('mock', user.uid, user.gid, target)

        progress.expects(:incomplete?).with('mock_setup').returns(false)
        cart_model.expects(:cartridge_action).never()

        progress.expects(:incomplete?).with('mock_erb').returns(false)
        cart_model.expects(:process_erb_templates).never()

        progress.expects(:incomplete?).with('mock_connect_frontend').returns(true)
        cart_model.expects(:connect_frontend).with(next_manifest)
        progress.expects(:mark_complete).with('mock_connect_frontend')

        ::OpenShift::Runtime::Upgrade.incompatible_upgrade(progress, cart_model, next_manifest, version, target, user)
      end

      def test_incompatible_done
        cart_model.expects(:setup_rewritten).with(next_manifest).returns(%w(a b/))
        File.expects(:file?).with('a').returns(true)
        File.expects(:directory?).with('a').returns(false)
        FileUtils.expects(:rm).with('a')

        File.expects(:directory?).with('b/').returns(true)
        File.expects(:file?).with('b/').returns(false)
        FileUtils.expects(:rm_r).with('b/')

        CartridgeRepository.expects(:overlay_cartridge).with(next_manifest, target)

        cart_model.expects(:unlock_gear).with(next_manifest).yields(next_manifest)
        cart_model.expects(:secure_cartridge).with('mock', user.uid, user.gid, target)

        progress.expects(:incomplete?).with('mock_setup').returns(false)
        cart_model.expects(:cartridge_action).never()

        progress.expects(:incomplete?).with('mock_erb').returns(false)
        cart_model.expects(:process_erb_templates).never()

        progress.expects(:incomplete?).with('mock_connect_frontend').returns(false)
        cart_model.expects(:connect_frontend).never()

        ::OpenShift::Runtime::Upgrade.incompatible_upgrade(progress, cart_model, next_manifest, version, target, user)
      end

    end
  end
end
