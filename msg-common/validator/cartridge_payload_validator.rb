module MCollective
  module Validator
    class Cartridge_payloadValidator

      VALIDATIONS = {
          '--action'                      => :validate_shellsafe,
          '--all'                         => :validate_boolean,
          '--blocks'                      => :validate_numeric,
          '--cart-name'                   => :validate_shellsafe,
          '--cartridge-vendor'            => :validate_shellsafe,
          '--component-name'              => :validate_shellsafe,
          '--connection-type'             => :validate_shellsafe,
          '--gear_uuid'                   => :validate_uuid,
          '--hook-name'                   => :validate_shellsafe,
          '--inodes'                      => :validate_numeric,
          '--input-args'                  => :validate_shellsafe,
          '--only-proxy-carts'            => :validate_boolean,
          '--parallel_concurrency_ratio'  => :validate_float,
          '--persist'                     => :validate_boolean,
          '--porcelain'                   => :validate_boolean,
          '--proxy-gears'                 => :validate_shellsafe,
          '--publishing-cart-name'        => :validate_shellsafe,
          '--rollback'                    => :validate_boolean,
          '--skip-hooks'                  => :validate_boolean,
          '--sync-new-gears'              => :validate_boolean,
          '--uuid'                        => :validate_uuid,
          '--web-gears'                   => :validate_shellsafe,
          '--with-aliases'                => :validate_array_shellsafe,
          '--with-alias-name'             => :validate_shellsafe,
          '--with-app-name'               => :validate_shellsafe,
          '--with-app-uuid'               => :validate_uuid,
          '--with-artifact-url'           => :validate_shellsafe,
          '--with-backup'                 => :validate_boolean,
          '--with-cartridge-manifest'     => :validate_string,
          '--with-cartridge-vendor'       => :validate_shellsafe,
          '--with-container-name'         => :validate_shellsafe,
          '--with-container-uuid'         => :validate_uuid,
          '--with-config'                 => :validate_hash,
          '--with-deployment-id'          => :validate_shellsafe,
          '--with-descriptors'            => :validate_boolean,
          '--with-expose-ports'           => :validate_boolean,
          '--with-force-clean-build'      => :validate_boolean,
          '--with-gears'                  => :validate_string,
          '--with-generate-app-key'       => :validate_boolean,
          '--with-hot-deploy'             => :validate_boolean,
          '--with-initial-deployment-dir' => :validate_boolean,
          '--with-iv'                     => :validate_shellsafe,
          '--with-keys'                   => :validate_shellsafe,
          '--with-key'                    => :validate_shellsafe,
          '--with-max-age'                => :validate_numeric,
          '--with-namespace'              => :validate_shellsafe,
          '--with-new-container-name'     => :validate_shellsafe,
          '--with-passphrase'             => :validate_shellsafe,
          '--with-paths'                  => :validate_string,
          '--with-path-target-options'    => :validate_string,
          '--with-priv-key'               => :validate_string,
          '--with-quota-blocks'           => :validate_numeric,
          '--with-quota-files'            => :validate_numeric,
          '--with-ref'                    => :validate_shellsafe,
          '--with-request-id'             => :validate_uuid,
          '--with-secret-token'           => :validate_shellsafe,
          '--with-software-version'       => :validate_shellsafe,
          '--with-ssh-key-comment'        => :validate_shellsafe,
          '--with-ssh-keys'               => :validate_array,
          '--with-ssh-key-type'           => :validate_shellsafe,
          '--with-ssh-key'                => :validate_shellsafe,
          '--with-ssl-cert'               => :validate_string,
          '--with-template-git-url'       => :validate_shellsafe,
          '--with-token'                  => :validate_shellsafe,
          '--with-uid'                    => :validate_numeric,
          '--with-value'                  => :validate_shellsafe,
          '--with-variables'              => :validate_string,
      }

      def self.validate(payload)
        Log.debug %Q(cartridge payload(#{payload.class}) #{payload.inspect})

        Validator.typecheck(payload, Hash)

        payload.each_key do |key|
          next unless payload[key]

          begin
            if VALIDATIONS.key?(key)
              send(VALIDATIONS[key], payload[key])
            else
              begin
                Validator.shellsafe(payload[key])
                Log.warn %Q(Node API payload argument #{key} is not explicitly validated and is shell safe.)
              rescue ValidatorError => e
                # If this is fatal, then n + 1 upgrades could be broken
                Log.warn %Q(Node API payload argument #{key} is not explicitly validated and is NOT shell safe.)
              end
            end
          rescue ValidatorError => e
            raise ValidatorError, %Q(#{key} is invalid, #{e.message})
          end
        end
      end

      def self.validate_hash(smth)
        Validator.typecheck(smth, Hash)
      end

      def self.validate_array(smth)
        Validator.typecheck(smth, Array)
      end

      def self.validate_array_shellsafe(smth)
        self.validate_array(smth)
        smth.each { |e| Validator.shellsafe(e) }
      end

      def self.validate_boolean(smth)
        Validator.typecheck(smth, :boolean)
      end

      def self.validate_numeric(smth)
        Validator.typecheck(smth, :numeric)
      end

      def self.validate_float(smth)
        Validator.typecheck(smth, :float)
      end

      def self.validate_shellsafe(smth)
        Validator.shellsafe(smth)
      end

      def self.validate_string(smth)
        Validator.typecheck(smth, :string)
      end

      def self.validate_uuid(smth)
        Validator.uuid(smth)
      end
    end
  end
end
