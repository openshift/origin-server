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
require 'safe_yaml'

SafeYAML::OPTIONS[:default_mode] = :unsafe

module OpenShift
  module ManagedFiles
    include NodeLogger

    # Immutable Files: Once instantiated in a gear this files cannot be changed. mode: 0644  own: root.uuid
    IMMUTABLE_FILES = %w(metadata/manifest.yml metadata/managed_files.yml env/OPENSHIFT_*_IDENT env/OPENSHIFT_*_DIR)

    # Turn blacklist into regexes
    FILENAME_BLACKLIST = %r{^\.(ssh|sandbox|tmp|env)}

    # Obtain values for an entry in a cartridge's managed_files.yml file
    #
    # cart - the cartridge you wish to query
    # type - the key you wish to obtain
    # process_files - whether or not to process the files before returning
    #
    # If process_files is true, the following actions are taken on the array:
    #  - relative entries are chrooted to the user's home directory or cartridge
    #  - entries are checked to ensure they stay within the user's home directory
    #  - patterns are expanded (see http://ruby-doc.org/core-1.9.3/Dir.html#method-c-glob)
    #    - patterns will only return existing files
    #  - explicit paths are returned regardless of existence
    #
    # Examples:
    #   managed_files(cart, :foo, false)
    #   # => ['a', '../b', '~/.c', '~/../bad']
    #
    #   managed_files(cart, :foo)
    #   # => ['cart_name/a', 'b', '.c'] # Note the bad entry would not be returned because it tries to escape home
    #
    # Returns an <code>Array</code> containing file names or strings
    #  - If these entries are processed, they are returned relative to the user's home directory
    def managed_files(cart, type, root, process_files = true)
      # Ensure that root ends in a slash
      root = "#{PathUtils.join(root,'')}/"
      # TODO: Is it possible to get a cart's full directory path?
      managed_files = PathUtils.join(root, cart.directory, 'metadata', 'managed_files.yml')
      unless File.exists?(managed_files)
        logger.info "#{managed_files} is missing"
        return []
      end

      # Ensure the this works with symbols or strings in yml file or argument
      file_patterns = YAML.load_file(managed_files, :safe => true, :deserialize_symbols => true).values_at(*[type.to_s,type.to_sym])
        .flatten.compact      # Remove any nils
        .map(&:strip)         # Remove leading/trailing whitespace
        .delete_if(&:empty?)  # Remove any empty patterns


      # Specify whether or not to do extra processing
      if process_files
        # If the file isn't ~/ make it relative to the cart directory
        file_patterns.map! do |line|
          abs_line = line.start_with?('~/') ? line : PathUtils.join('~/',cart.directory,line)
          # Ensure that any patterns that try to traverse upward are exposed
          abs_line = File.expand_path(abs_line.sub(/^~\//,root))
          if line.end_with?('/') && !abs_line.end_with?('/')
            abs_line = "#{abs_line}/"
          end
          abs_line
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

        IMMUTABLE_FILES.each do |name|
          name.gsub!('*', cart.short_name)
          wanted_files.delete(PathUtils.join(root, cart.directory, name))
        end

        # Return files as relative to root
        wanted_files.map{|x| x[root.length..-1]}
      else
        file_patterns
      end
    end

    # Obtain the 'locked_files' entry from the managed_files.yml file
    #
    # cartridge - the cartridge you wish to query
    #
    # Returns an array of matching file entries. Entries are only allowed if:
    #  - they do not match a blacklisted pattern
    #  - they are in 'app-root', the cartridge's directory, or dot files/dirs in the user's home directory
    def locked_files(cartridge)
      locked_files = managed_files(cartridge, :locked_files, @user.homedir)

      files = []
      locked_files.each do |line|
        # Do not allow blacklisted directories
        if line =~ FILENAME_BLACKLIST
          logger.info("#{cartridge.directory} attempted lock/unlock on black listed entry [#{line}]")
        elsif line !~ /^(app-root\/|\.[^\/]+|#{cartridge.directory}\/)/ # Only allow files in app-root, the cart directory, or dot files/dirs (if they pass blacklist check)
          logger.info("#{cartridge.directory} attempted lock/unlock on out-of-bounds entry [#{line}]")
        else
          abs_line = PathUtils.join(@user.homedir, line)
          if line.end_with?('/') && !abs_line.end_with?('/')
            abs_line = "#{abs_line}/"
          end
          files << abs_line
        end
      end
      files
    end

    # Obtain the 'snapshot_exclusions' entry from the managed_files.yml file
    #
    # cartridge - the cartridge you wish to query
    #
    # Returns an array of matching file entries.
    def snapshot_exclusions(cartridge)
      managed_files(cartridge, :snapshot_exclusions, @user.homedir)
    end

    # Obtain the 'setup_rewritten' entry from the managed_files.yml file
    #
    # cartridge - the cartridge you wish to query
    #
    # Returns an array of matching file entries.
    def setup_rewritten(cartridge)
      managed_files(cartridge, :setup_rewritten, @user.homedir)
    end

    # Obtain the 'restore_transforms' entry from the managed_files.yml file
    #
    # cartridge - the cartridge you wish to query
    #
    # Returns an array of transform scripts (sed commands)
    def restore_transforms(cartridge)
      # Do not let managed_files process the entries, since they will be sed scripts
      managed_files(cartridge, :restore_transforms, @user.homedir, false)
    end

    # Obtain the 'processed_templates' entry from the managed_files.yml file
    #
    # cartridge - the cartridge you wish to query
    #
    # Returns an array of matching file entries.
    def processed_templates(cartridge)
      managed_files(cartridge, :processed_templates, @user.homedir)
    end
  end
end
