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

require 'openshift-origin-node/utils/node_logger'

module OpenShift
  module Utils
    # Class represents the OpenShift/Ruby analogy of C environ(7)
    class Environ
      # Load the combined cartridge environments for a gear
      # @param [String] gear_dir       Home directory of the gear
      # @return [Hash<String,String>]  hash[Environment Variable] = Value
      def self.for_gear(gear_dir)
        load("/etc/openshift/env",
             File.join(gear_dir, '.env'),
             File.join(gear_dir, '*', 'env'))
      end

      # @param [String] cartridge_dir       Home directory of the gear
      # @return [Hash<String,String>]  hash[Environment Variable] = Value
      def self.for_cartridge(cartridge_dir)
        load("/etc/openshift/env",
             File.join(Pathname.new(cartridge_dir).parent.to_path, '.env'),
             File.join(cartridge_dir, 'env'))
      end

      # Read a Gear's + n number cartridge environment variables into a environ(7) hash
      # @param [String]               env_dir of gear to be read
      # @return [Hash<String,String>] environment variable name: value
      def self.load(*dirs)
        dirs.each_with_object({}) do |env_dir, env|
          # add wildcard for globbing if needed
          env_dir += '/*' if not env_dir.end_with? '*'

          # Find, read and load environment variables into a hash
          Dir[env_dir].each do |file|
            next if file.end_with? '.erb'
            next unless File.file? file

            begin
              contents = nil
              File.open(file) do |input|
                contents = input.read.chomp
                next if contents.empty?

                index    = contents.index('=')
                parsed_contents = contents[(index + 1)..-1]
                parsed_contents.gsub!(/\A["']|["']\Z/, '')
                env[File.basename(file)] = parsed_contents
              end
            rescue => e
              msg = "Failed to process: #{file}"
              unless contents.nil?
                msg << " [#{contents}]"
              end
              msg << ": "
              msg << (
                case e
                when SystemCallError
                  # This catches filesystem level errors
                  # We split the message because it contains the filename
                  e.message.split(' - ').first
                else
                  e.message
                end
              )
              NodeLogger.logger.info( msg )
            end
          end
        end
      end

    end
  end
end
