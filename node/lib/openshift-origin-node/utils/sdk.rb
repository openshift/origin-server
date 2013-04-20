module OpenShift
  module Utils
    class Sdk
      MARKER = 'CARTRIDGE_VERSION_2'

      def self.new_sdk_app?(gear_home)
        File.exists?(File.join(gear_home, '.env', MARKER))
      end

      def self.mark_new_sdk_app(gear_home)
        IO.write(File.join(gear_home, '.env', MARKER), '2', 0)
      end

      def self.node_default_model(config)
        v1_marker_exist = File.exist?(File.join(config.get('GEAR_BASE_DIR'), '.settings', 'v1_cartridge_format'))
        v2_marker_exist = File.exist?(File.join(config.get('GEAR_BASE_DIR'), '.settings', 'v2_cartridge_format'))

        if v1_marker_exist and v2_marker_exist
          raise 'Node cannot create both v1 and v2 formatted cartridges. Delete one of the cartridge format marker files'
        end
        # TODO: When v2 is the default cartridge format change this test...
        if v2_marker_exist
          return :v2
        else
          return :v1
        end
      end
    end
  end
end
