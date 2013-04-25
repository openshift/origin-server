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
  module ManagedFiles
    include NodeLogger

    # Turn blacklist into regexes
    FILENAME_BLACKLIST = %r{^\.(ssh|sandbox|tmp|env)}

    def managed_files(cart, type, root = nil)
      managed_files = File.join(cart.directory, 'metadata', 'managed_files.yml')

      # Ensure the this works with symbols or strings in yml file or argument
      file_patterns = YAML.load_file(managed_files).values_at(*[type.to_s,type.to_sym])
        .flatten.compact      # Remove any nils
        .map(&:strip)         # Remove leading/trailing whitespace
        .delete_if(&:empty?)  # Remove any empty patterns

      # If we pass a root, do extra processing
      # If not, just return the patterns
      if root
        # If the file isn't ~/ make it relative to the cart directory
        file_patterns.map! do |line|
          abs_line = line.start_with?('~/') ?  line : File.join('~/',cart.directory,line)
          # Ensure that any patterns that try to traverse upward are exposed
          File.expand_path(abs_line.sub(/^~/,root))
        end

        # Ensure the file patterns are in the root
        (good_patterns, bad_patterns) = file_patterns.partition{|x| x.start_with?(root)}
        # Log bad file paths
        bad_patterns.each{|line| logger.info "#{cart.directory} #{type} includes out-of-bounds entry [#{line}]" }

        wanted_files = good_patterns.map do |pattern|
          if pattern =~ /\*/
            # Ensure only files are globbed and not dirs
            Dir.glob(pattern, File::FNM_DOTMATCH).select{ |f| File.file?(f) }
          else
            # Use all explicit patterns
            pattern
          end
        end.flatten

        # Return files as relative to root
        wanted_files.map{|x| x.sub("#{root}/",'') }
      else
        file_patterns
      end
    end

    # lock_files(cartridge_object) -> Array.new(file_names)
    #
    # Returns an <code>Array</code> object containing the file names the cartridge author wishes to manipulate
    #
    #   v2_cart_model.lock_files(cartridge)
    def lock_files(cartridge)
      locked_files = managed_files(cartridge, :locked_files, @user.homedir)

      # Only allow files in app-root, the cart directory, or dot files (if they pass blacklist check)
      accepted_locations = Regexp.new("^(app-root|\\.|#{cartridge.directory})")

      locked_files.each_with_object([]) do |line, memo|
        case
          # Do not allow blacklisted directories
          when line =~ FILENAME_BLACKLIST
            logger.info("#{cartridge.directory} attempted lock/unlock on black listed entry [#{line}]")
          when !(line =~ accepted_locations)
            logger.info("#{cartridge.directory} attempted lock/unlock on out-of-bounds entry [#{line}]")
          else
            memo << line
        end
      end
    end

    # snapshot_exclusions(cartridge_object) -> Array.new(file_names)
    #
    # Returns an <code>Array</code> object containing the file names the cartridge author wishes to exclude from snapshots
    #
    #   v2_cart_model.snapshot_exclusions(cartridge)
    def snapshot_exclusions(cartridge)
      managed_files(cartridge, :snapshot_exclusions, @user.homedir)
    end

    # setup_rewritten(cartridge_object) -> Array.new(file_names)
    #
    # Returns an <code>Array</code> object containing the file names that will be cleared on subsequent setup runs
    #
    #   v2_cart_model.setup_rewritten(cartridge)
    def setup_rewritten(cartridge)
      managed_files(cartridge, :setup_rewritten, @user.homedir)
    end

    # restore_transforms(cartridge_object) -> Array.new(file_names)
    #
    # Returns an <code>Array</code> object containing the file names the cartridge author wishes to use to modify files after a restore
    #
    #   v2_cart_model.restore_transforms(cartridge)
    def restore_transforms(cartridge)
      managed_files(cartridge, :restore_transforms, @user.homedir)
    end

    # process_templates(cartridge_object) -> Array.new(file_names)
    #
    # Returns an <code>Array</code> object containing the file names the cartridge author wishes to process, such as ERB templates
    #
    #   v2_cart_model.process_templates(cartridge)
    def process_templates(cartridge)
      managed_files(cartridge, :processed_templates, @user.homedir)
    end
  end
end
