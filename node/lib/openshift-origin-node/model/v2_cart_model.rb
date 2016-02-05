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

require 'rubygems'
require 'shellwords'
require 'openshift-origin-node/model/application_repository'
require 'openshift-origin-node/model/cartridge_repository'
require 'openshift-origin-common/models/manifest'
require 'openshift-origin-node/model/pub_sub_connector'
require 'openshift-origin-node/model/gear_registry'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/selinux_context'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-node/utils/cgroups'
require 'openshift-origin-node/utils/sdk'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-common/utils/path_utils'
require 'openshift-origin-node/utils/application_state'
require 'openshift-origin-node/utils/managed_files'
require 'openshift-origin-node/utils/sanitize'

module OpenShift
  module Runtime

    class MissingCartridgeIdentError < RuntimeError
    end

    class FileLockError < Exception
      attr_reader :filename

      def initialize(msg = nil, filename)
        super(msg)
        @filename = filename
      end
    end

    class FileUnlockError < Exception
      attr_reader :filename

      def initialize(msg = nil, filename)
        super(msg)
        @filename = filename
      end
    end

    class V2CartridgeModel
      include NodeLogger

      def initialize(config, container, state, hourglass)
        @config     = config
        @container  = container
        @state      = state
        @timeout    = 30
        @cartridges = {}
        @hourglass  = hourglass
      end

      def stop_lock
        PathUtils.join(@container.container_dir, 'app-root', 'runtime', '.stop_lock')
      end

      def stop_lock?
        File.exists?(stop_lock)
      end

      ##
      # Yields a +Cartridge+ instance for each cartridge in the gear.
      def each_cartridge
        process_cartridges do |cartridge_dir|
          cartridge = get_cartridge_from_directory(File.basename(cartridge_dir))
          yield cartridge
        end
      end

      ##
      # Returns the primary +Cartridge+ in the gear as specified by the
      # +OPENSHIFT_PRIMARY_CARTRIDGE_DIR+ environment variable, or +Nil+ if
      # no primary cartridge is present.
      def primary_cartridge
        env              = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
        primary_cart_dir = env['OPENSHIFT_PRIMARY_CARTRIDGE_DIR']

        raise "No primary cartridge detected in gear #{@container.uuid}" unless primary_cart_dir and !primary_cart_dir.empty?

        return get_cartridge_from_directory(File.basename(primary_cart_dir))
      end

      ##
      # Returns the +Cartridge+ in the gear whose +web_proxy+ flag is set to
      # true, nil otherwise
      def web_proxy
        each_cartridge do |cartridge|
          return cartridge if cartridge.web_proxy?
        end
        nil
      end

      ##
      # Returns true if the primary +Cartridge+ is also the +web_proxy+.
      # This occurs in the case of applications that have a web cartridge
      # that is deployed on a platform different than the web proxy's.
      def standalone_web_proxy?
        (web_proxy != nil) and (web_proxy.name == primary_cartridge.name)
      end

      ##
      # Detects and returns a builder +Cartridge+ in the gear if present, otherwise +nil+.
      def builder_cartridge
        builder_cart = nil
        each_cartridge do |c|
          if c.categories.include? 'ci_builder'
            builder_cart = c
            break
          end
        end
        builder_cart
      end

      # FIXME: Once Broker/Node protocol updated to provided necessary information this hack must go away
      def map_cartridge_name(cartridge_name)
        results = cartridge_name.split(/\-([0-9\.]+)$/)
        if !Runtime::Manifest.valid_cartridge_name?(cartridge_name)
          raise "Invalid cartridge identifier '#{cartridge_name}': expected name-version"
        end
        results
      end

      def cartridge_directory(cart_name)
        name, _  = map_cartridge_name(cart_name)
        cart_dir = Dir.glob(PathUtils.join(@container.container_dir, "#{name}"))
        raise "Ambiguous cartridge name #{cart_name}: found #{cart_dir}:#{cart_dir.size}" if 1 < cart_dir.size
        raise "Cartridge directory not found for #{cart_name}" if  1 > cart_dir.size

        File.basename(cart_dir.first)
      end

      # Load the cartridge's local manifest from the Broker token 'name-version'
      def get_cartridge(cart_name)
        unless @cartridges.has_key? cart_name
          cart_dir = ''
          begin
            cart_dir = cartridge_directory(cart_name)

            @cartridges[cart_name] = get_cartridge_from_directory(cart_dir)
          rescue Exception => e
            logger.error e.message
            logger.error e.backtrace.join("\n")
            raise "Failed to get cartridge '#{cart_name}' from #{cart_dir} in gear #{@container.uuid}: #{e.message}"
          end
        end

        @cartridges[cart_name]
      end

      # Load cartridge's local manifest from cartridge directory name
      def get_cartridge_from_directory(directory)
        raise "Directory name is required" if (directory == nil || directory.empty?)

        unless @cartridges.has_key? directory
          cartridge_path = PathUtils.join(@container.container_dir, directory)
          manifest_path  = PathUtils.join(cartridge_path, 'metadata', 'manifest.yml')
          ident_path     = Dir.glob(PathUtils.join(cartridge_path, 'env', "OPENSHIFT_*_IDENT")).first

          raise "Cartridge manifest not found: #{manifest_path} missing" unless File.exists?(manifest_path)
          raise MissingCartridgeIdentError, "Cartridge Ident not found in #{cartridge_path}" unless ident_path

          _, _, version, _ = Runtime::Manifest.parse_ident(IO.read(ident_path))

          @cartridges[directory] = Manifest.new(manifest_path, version, :file, @container.container_dir)
        end
        @cartridges[directory]
      end

      # Load the cartridge's local manifest from the Broker token 'name-version'
      def get_cartridge_fallback(cart_name)
        directory  = cartridge_directory(cart_name)
        _, version = map_cartridge_name(cart_name)

        raise "Directory name is required" if (directory == nil || directory.empty?)

        cartridge_path = PathUtils.join(@container.container_dir, directory)
        manifest_path  = PathUtils.join(cartridge_path, 'metadata', 'manifest.yml')

        raise "Cartridge manifest not found: #{manifest_path} missing" unless File.exists?(manifest_path)

        Manifest.new(manifest_path, version, :file, @container.container_dir)
      end

      # Optionally back up the gear directory contents to a
      # user-specified "dump site" if a gear is rolled back due to
      # failure during app create
      def archive_gear()
        archive_dir = @config.get("ARCHIVE_DESTROYED_GEARS_DIR", nil)
        archive_compress = @config.get("ARCHIVE_DESTROYED_GEARS_COMPRESSION", 'bzip2').downcase
        archive_suffix = ""
        if not [ 'bzip2', 'gzip', 'none' ].include? archive_compress
          archive_compress = 'bzip2'
        end
        case archive_compress
        when 'bzip2'
          archive_compress = "--#{archive_compress}"
          archive_suffix = '.bz2'
        when 'gzip'
          archive_compress = "--#{archive_compress}"
          archive_suffix = '.gz'
        when 'none'
          archive_compress = ''
          archive_suffix = ''
        end
        if @config.get_bool("ARCHIVE_DESTROYED_GEARS", false)
          if not archive_dir
            logger.warn "Cannot archive destroyed gears; ARCHIVE_DESTROYED_GEARS_DIR is not set in node.conf"
            return
          elsif not File.directory? archive_dir
            logger.warn "Cannot archive destroyed gears; #{archive_dir} is not a directory"
            return
          elsif not File.writable? archive_dir
            logger.warn "Cannot archive destroyed gears; #{archive_dir} is not writable"
            return
          elsif File.world_readable? archive_dir or File.world_writable? archive_dir
            logger.warn "Cannot archive destroyed gears; #{archive_dir} is world readable and/or writable"
            return
          end
          archive_filespec = PathUtils.join(archive_dir, "#{@container.application_name}-#{@container.uuid}.tar#{archive_suffix}")
          if File.exists? archive_filespec
            logger.warn "Cannot archive destroyed gears; #{archive_filespec} already exists"
          else
            command = "tar --selinux --acls --preserve-permissions --preserve-order --create #{archive_compress} --file=#{archive_filespec} #{@container.container_dir}"
            tarout, tarerr, rc = Utils.oo_spawn(command)
            if rc == 1
              logger.warn "Some files may have changed while running \"#{command}\"; rc=#{rc}, stdout=#{tarout}, stderr=#{tarerr}"
            elsif rc != 0
              logger.warn "Error occurred running \"#{command}\"; rc=#{rc}, stdout=#{tarout}, stderr=#{tarerr}"
            end
          end
        end
      end

      # destroy(skip_hooks = false, is_group_rollback = false) -> [buffer, '', 0]
      #
      # Remove all cartridges from a gear and delete the gear.  Accepts
      # and discards any parameters to comply with the signature of V1
      # require, which accepted a single argument.
      #
      # destroy() => ['', '', 0]
      def destroy(skip_hooks = false, is_group_rollback = false)
        logger.info('V2 destroy')

        buffer = ''
        begin
          # only archive if app create failed
          archive_gear if is_group_rollback
          unless skip_hooks
            each_cartridge do |cartridge|
              unlock_gear(cartridge, false) do |c|
                begin
                  buffer << cartridge_teardown(c.directory, false)
                rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
                  logger.warn("Cartridge teardown operation failed on gear #{@container.uuid} for cartridge #{c.directory}: #{e.message} (rc=#{e.rc})")
                end
              end
            end
          end
        rescue Exception => e
          logger.warn("Cartridge teardown operation failed on gear #{@container.uuid} for some cartridge: #{e.message}")
          buffer << "CLIENT_ERROR: Abandoned cartridge teardowns. There may be extraneous data left on system."
        end

        # FIXME: V1 contract is there a better way?
        [buffer, '', 0]
      end

      # tidy() -> nil
      #
      # Run tidy operation on each cartridge on a gear
      #
      # tidy()
      def tidy
        each_cartridge do |cartridge|
          begin
            output = do_control('tidy', cartridge)
          rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
            logger.warn("Tidy operation failed for cartridge #{cartridge.name} on "\
                      "gear #{@container.uuid}: #{e.message} (rc=#{e.rc}), output=#{output}")
          end
        end
      end

      # configure(Ident, template_git_url, manifest) -> stdout
      #
      # Add a cartridge to a gear
      #
      # configure(ident)
      # configure(ident, 'git://')
      # configure(ident, 'git://', 'git://')
      def configure(ident, template_git_url = nil, manifest = nil)
        output                 = ''
        cartridge              = if manifest
                                   logger.debug("Loading #{ident.name} from manifest for #{@container.uuid}")
                                   Runtime::Manifest.new(manifest, ident.software_version)
                                 else
                                   CartridgeRepository.instance.select(
                                       ident.cartridge_vendor,
                                       ident.name,
                                       ident.software_version)
                                 end

        ::OpenShift::Runtime::Utils::Cgroups.new(@container.uuid).boost do
          create_cartridge_directory(cartridge, ident.software_version)
          # Note: the following if statement will check the following criteria long-term:
          # 1. Is the app scalable?
          # 2. Is this the head gear?
          # 3. Is this the first time the platform has generated an ssh key?
          #
          # In the current state of things, the following check is sufficient to test all
          # of these criteria, and we do not have a way to explicitly check the first two
          # criteria.  However, it should be considered a TODO to add more explicit checks.
          if cartridge.web_proxy?
            ::OpenShift::Runtime::GearRegistry.new(@container)
          end

          create_private_endpoints(cartridge)

          unlock_gear(cartridge) do |c|
            expected_entries = Dir.glob(PathUtils.join(@container.container_dir, '*'))

            create_dependency_directories(cartridge)

            output << cartridge_action(cartridge, 'setup', ident.software_version, true)
            output << process_erb_templates(c)
            output << cartridge_action(cartridge, 'install', ident.software_version)

            actual_entries  = Dir.glob(PathUtils.join(@container.container_dir, '*'))
            illegal_entries = actual_entries - expected_entries
            unless illegal_entries.empty?
              raise RuntimeError.new(
                        "Cartridge created the following directories in the gear home directory: #{illegal_entries.join(', ')}")
            end

            output << populate_gear_repo(c.directory, template_git_url) if populate_repository?(cartridge, template_git_url)
          end

          validate_cartridge(cartridge)

          output << connect_frontend(cartridge)
        end

        logger.info "configure output: #{Runtime::Utils.sanitize_credentials(output)}"
        return output
      rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
        rc_override = e.rc < 100 ? 157 : e.rc
        raise ::OpenShift::Runtime::Utils::Sdk.translate_shell_ex_for_client(e, rc_override)
      rescue => e
        logger.error "Unexpected error during configure: #{e.message} (#{e.class})\n  #{e.backtrace.join("\n  ")}"
        ex = RuntimeError.new(Utils::Sdk.translate_out_for_client("Unexpected error: #{e.message}", :error))
        ex.set_backtrace(e.backtrace)
        raise ex
      end

      def validate_cartridge(manifest)
        illegal_overrides = ::OpenShift::Runtime::Utils::Environ.load(PathUtils.join(@container.container_dir, '.env')).keys &
            ::OpenShift::Runtime::Utils::Environ.load(PathUtils.join(@container.container_dir, manifest.directory, 'env')).keys

        # Older gears may have these and cartridges are allowed to override them
        illegal_overrides.delete('LD_LIBRARY_PATH')
        illegal_overrides.delete('PATH')

        unless illegal_overrides.empty?
          raise RuntimeError.new(
                    "Cartridge attempted to override the following gear environment variables: #{illegal_overrides.join(', ')}")
        end
      end

      def post_install(cartridge, software_version, options = {})
        output = cartridge_action(cartridge, 'post_install', software_version)
        options[:out].puts(output) if options[:out]
        output
      end

      def post_configure(cartridge_name)
        output = ''

        name, software_version = map_cartridge_name(cartridge_name)
        cartridge              = get_cartridge(name)

        ::OpenShift::Runtime::Utils::Cgroups.new(@container.uuid).boost do
          if cartridge.name == primary_cartridge.name and empty_repository?
            output << "CLIENT_MESSAGE: An empty Git repository has been created for your application.  Use 'git push' to add your code."
          else
            if (@state.value == State::STARTED)
              output << start_cartridge('restart', cartridge, user_initiated: true)
            else
              output << start_cartridge('start', cartridge, user_initiated: true)
            end
          end
          output << cartridge_action(cartridge, 'post_install', software_version)
        end

        logger.info("post-configure output: #{Runtime::Utils.sanitize_credentials(output)}")
        output
      rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
        raise ::OpenShift::Runtime::Utils::Sdk.translate_shell_ex_for_client(e, 157)
      end

      # deconfigure(Ident) -> nil
      #
      # Remove cartridge from gear with the following workflow:
      #
      #   1. Delete private endpoints
      #   2. Stop the cartridge
      #   3. Execute the cartridge `control teardown` action
      #   4. Disconnect the frontend for the cartridge
      #   5. Delete the cartridge directory
      #
      # If the cartridge stop or teardown operations fail, the error output will be
      # captured, but the frontend will still be disconnect and the cartridge directory
      # will be deleted.
      #
      # deconfigure(ident)
      def deconfigure(ident)
        teardown_output = ''

        cartridge = nil
        begin
          cartridge = get_cartridge(ident.to_name)
        rescue
          teardown_output << "CLIENT_ERROR: Corrupted cartridge #{ident} removed. There may be extraneous data left on system.\n"
          logger.warn("Corrupted cartridge #{@container.uuid}/#{ident} removed. There may be extraneous data left on system.")

          begin
            logger.warn("Corrupted cartridge #{@container.uuid}/#{ident}. Attempting to auto-correct for deconfigure using local manifest.yml.")
            cartridge = get_cartridge_fallback(ident.to_name)
          rescue
            logger.warn("Corrupted cartridge #{@container.uuid}/#{ident}. Attempting to auto-correct for deconfigure resorting to CartridgeRepository.")
            begin
              cartridge = CartridgeRepository.instance.select(ident.cartridge_vendor,
                                                              ident.name,
                                                              ident.software_version)
            rescue
              logger.warn("Cartridge #{ident} not found in CartridgeRepostory.")
              teardown_output << "Cartridge #{ident} not found on the gear or in the CartridgeRepository. It is most likely a downloaded cartridge that failed to configure and was removed."
              return teardown_output
            end
          end

          write_environment_variables(
              PathUtils.join(@container.container_dir, cartridge.directory, 'env'),
              {"#{cartridge.short_name}_IDENT" => ident.to_s})
        end

        delete_private_endpoints(cartridge)
        ::OpenShift::Runtime::Utils::Cgroups.new(@container.uuid).boost do
          begin
            stop_cartridge(cartridge, user_initiated: true)
            unlock_gear(cartridge, false) do |c|
              teardown_output << cartridge_teardown(c.directory)
            end
          rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
            teardown_output << ::OpenShift::Runtime::Utils::Sdk::translate_out_for_client(e.stdout, :error)
            teardown_output << ::OpenShift::Runtime::Utils::Sdk::translate_out_for_client(e.stderr, :error)
          rescue RuntimeError => e
              teardown_output <<  "\n#{e.message}"
          ensure
            disconnect_frontend(cartridge)
            delete_cartridge_directory(cartridge)
          end
        end

        teardown_output
      end

      # unlock_gear(cartridge_name) -> nil
      #
      # Prepare the given cartridge for the cartridge author
      #
      #   v2_cart_model.unlock_gear('php-5.3')
      def unlock_gear(cartridge, relock=true)
        begin
          do_unlock(@container.locked_files(cartridge))
          yield cartridge
        ensure
          do_lock(relock ? @container.locked_files(cartridge) : [])
        end
        nil
      end

      # do_unlock_gear(array of file names) -> array
      #
      # Take the given array of file system entries and prepare them for the cartridge author
      #
      #   v2_cart_model.do_unlock_gear(entries)
      def do_unlock(entries)
        entries.each do |entry|
          if entry.end_with?('/')
            entry.chomp!('/')
            FileUtils.mkpath(entry, mode: 0755) unless File.exist? entry
          else
            # FileUtils.touch not used as it doesn't support mode
            File.new(entry, File::CREAT|File::TRUNC|File::WRONLY, 0644).close() unless File.exist?(entry)
          end
          # It is expensive doing one file at a time but...
          # ...it allows reporting on the failed command at the file level
          # ...we don't have to worry about the length of argv
          begin
            @container.set_rw_permission(entry)
          rescue Exception => e
            raise FileUnlockError.new("Failed to unlock file system entry [#{entry}]: #{e}",
                                      entry)
          end
        end

        begin
          @container.set_rw_permission(@container.container_dir)
        rescue Exception => e
          raise FileUnlockError.new(
                    "Failed to unlock gear home [#{@container.container_dir}]: #{e}",
                    @container.container_dir)
        end
      end

      # do_lock_gear(array of file names) -> array
      #
      # Take the given array of file system entries and prepare them for the application developer
      #    v2_cart_model.do_lock_gear(entries)
      def do_lock(entries)
        # It is expensive doing one file at a time but...
        # ...it allows reporting on the failed command at the file level
        # ...we don't have to worry about the length of argv
        entries.each do |entry|
          begin
            @container.set_ro_permission(entry)
          rescue Exception => e
            raise OpenShift::Runtime::FileLockError.new("Failed to lock file system entry [#{entry}]: #{e}",
                                                        entry)
          end
        end

        begin
          @container.set_ro_permission(@container.container_dir)
        rescue Exception => e
          raise OpenShift::Runtime::FileLockError.new("Failed to lock gear home [#{@container.container_dir}]: #{e}",
                                                      @container.container_dir)
        end
      end

      # create_cartridge_directory(Manifest, version) -> nil
      #
      # Create the cartridges home directory
      #
      #   v2_cart_model.create_cartridge_directory(manifest, '5.3')
      def create_cartridge_directory(cartridge, software_version)
        logger.info("Creating cartridge directory #{@container.uuid}/#{cartridge.directory}")

        target = PathUtils.join(@container.container_dir, cartridge.directory)
        CartridgeRepository.instantiate_cartridge(cartridge, target)

        ident = Runtime::Manifest.build_ident(cartridge.cartridge_vendor,
                                              cartridge.name,
                                              software_version,
                                              cartridge.cartridge_version)

        envs                                  = {}
        envs["#{cartridge.short_name}_DIR"]   = target + File::SEPARATOR
        envs["#{cartridge.short_name}_IDENT"] = ident

        write_environment_variables(PathUtils.join(target, 'env'), envs)

        envs.clear
        envs['namespace'] = @container.namespace if @container.namespace

        # If there's not already a primary cartridge on the gear, assume
        # the new cartridge is the primary.
        current_gear_env = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
        unless current_gear_env['OPENSHIFT_PRIMARY_CARTRIDGE_DIR']
          envs['primary_cartridge_dir'] = target + File::SEPARATOR
          logger.info("Cartridge #{cartridge.name} recorded as primary within gear #{@container.uuid}")
        end

        unless envs.empty?
          write_environment_variables(PathUtils.join(@container.container_dir, '.env'), envs)
        end

        # Gear level actions: Placed here to be off the V1 code path...
        old_path = PathUtils.join(@container.container_dir, '.env', 'PATH')
        File.delete(old_path) if File.file? old_path

        secure_cartridge(cartridge.short_name, @container.uid, @container.gid, target)

        logger.info("Created cartridge directory #{@container.uuid}/#{cartridge.directory}")
        nil
      end

      # Creates cartridge dependency directories listed in managed_files.yml.
      #
      # The directories are created in ~/app-root/runtime/dependencies and/or
      # ~/app-root/runtime/build-dependencies.
      #
      # This method also creates symlinks from the cartridge directory to the appropriate
      # symlink in ~/app-root/runtime/{dependencies,build-dependencies}. For example:
      #
      # ~/php/phplib -> ~/app-root/runtime/dependencies/php/phplib
      def create_dependency_directories(cartridge)

        %w(build-dependencies dependencies).each do |dependencies_dir_name|
          if dependencies_dir_name == 'build-dependencies'
            dirs = @container.build_dependency_dirs(cartridge)
          else
            dirs = @container.dependency_dirs(cartridge)
          end

          dirs.each do |entry|
            if entry.is_a?(String)
              # e.g. phplib
              link = target = entry
            else
              # e.g. jbossas/standalone/deployments
              link = entry.keys[0]

              # e.g. jbossas/deployments
              target = entry.values[0]
            end

            # create the target dir inside the runtime dir
            dependencies_dir = PathUtils.join(@container.container_dir, 'app-root', 'runtime', dependencies_dir_name)

            FileUtils.mkdir_p(PathUtils.join(dependencies_dir, target))

            full_link = PathUtils.join(@container.container_dir, link)

            # if the link is something like foo/bar/baz or jbossas/standalone/deployments,
            # need to mkdir -p everything up to the link (foo/bar or jbossas/standalone)
            #
            # also need to chown -R the first directory in the path that is new, e.g.
            # if jbossas exists but standalone is new, chown -R standalone
            if link.count('/') > 0
              parts = link.split('/')

              # start the path at the home dir
              path = @container.container_dir

              parts.each do |part|
                # check each segment of the link
                path = PathUtils.join(path, part)

                # if the path exists, skip to the next one
                next if File.exist?(path)

                # if the path doesn't exist, exit the loop
                #
                # path is now either the first dir in the link's path that doesn't exist
                # or it's the link itself
                break
              end

              # now that we've figured out the portion of the link path that doesn't exist
              # go ahead and create all the parent dirs for the link
              FileUtils.mkdir_p(PathUtils.join(@container.container_dir, parts[0..-2]))

              # if the path != the full link, we need to change ownership for the new
              # dir and below
              if path != full_link
                PathUtils.oo_chown_R(@container.uid, @container.gid, path)
              end
            end

            full_target = PathUtils.join(@container.container_dir, 'app-root', 'runtime', dependencies_dir_name, target)

            # the link only needs to be created when the cartridge is installed,
            # which means it's running via mcollective as root
            #
            # once the link exists, it should never need to change and does not
            # need to be recreated during a clean build
            if !File.exist?(full_link)
              FileUtils.ln_s(full_target, full_link)

              # make sure the symlink is owned by the gear user
              PathUtils.oo_lchown(@container.uid, @container.gid, full_link)
            end

            # in case anything was created below the dependencies dir, correct its ownership
            PathUtils.oo_chown_R(@container.uid, @container.gid, dependencies_dir)
          end
        end
      end

      def secure_cartridge(short_name, uid, gid=uid, cartridge_home)
        @container.set_rw_permission_R(cartridge_home)

        files = ManagedFiles::IMMUTABLE_FILES.collect do |file|
          file = file.gsub('*', short_name)
          file = PathUtils.join(cartridge_home, file)
          file if File.exist?(file)
        end || []
        files.compact!

        unless files.empty?
          @container.set_ro_permission(files)
          FileUtils.chmod(0644, files)
        end
      end

      ##
      # Write out environment variables.
      def write_environment_variables(path, hash, prefix = true)
        FileUtils.mkpath(path) unless File.exist? path

        hash.each_pair do |k, v|
          name = k.to_s.upcase

          if prefix
            name = "OPENSHIFT_#{name}"
          end

          pathname = PathUtils.join(path, name)
          begin
            File.open(pathname, 'w', 0666) do |f|
              f.write(v)
            end
          rescue Exception => e
            logger.warn "Got #{e.class} exception writing #{pathname}: #{e.message}"
          end
        end
      end

      def delete_cartridge_directory(cartridge)
        logger.info("Deleting cartridge directory for #{@container.uuid}/#{cartridge.directory}")
        # TODO: rm_rf correct?
        FileUtils.rm_rf(PathUtils.join(@container.container_dir, cartridge.directory))
        logger.info("Deleted cartridge directory for #{@container.uuid}/#{cartridge.directory}")
      end

      # :call-seq:
      #   model.populate_gear_repo(cartridge name) => nil
      #   model.populate_gear_repo(cartridge name, application git template url) -> nil
      #
      # Populate the gear git repository with a sample application
      #
      #   model.populate_gear_repo('ruby-1.9')
      #   model.populate_gear_repo('ruby-1.9', 'http://rails-example.example.com')
      def populate_gear_repo(cartridge_name, template_url = nil)
        logger.info "Creating gear repo for #{@container.uuid}/#{cartridge_name} from `#{template_url}`"

        repo = ApplicationRepository.new(@container)
        if template_url.nil?
          repo.populate_from_cartridge(cartridge_name)
        elsif OpenShift::Git.empty_clone_spec?(template_url)
          repo.populate_empty(cartridge_name)
        else
          repo.populate_from_url(cartridge_name, template_url)
        end

        if repo.exist?
          repo.archive(PathUtils.join(@container.container_dir, 'app-root', 'runtime', 'repo'), 'master')
        end
        ""
      end

      # process_erb_templates(cartridge_name) -> nil
      #
      # Search cartridge for any remaining <code>erb</code> files render them
      def process_erb_templates(cartridge)
        buffer = ''

        directory = PathUtils.join(@container.container_dir, cartridge.name)
        logger.info "Processing ERB templates for #{cartridge.name}"

        env  = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir, directory)
        erbs = @container.processed_templates(cartridge).map { |x| PathUtils.join(@container.container_dir, x) }
        erbs.delete_if do |erb_file|
          reject = !File.exists?(erb_file)

          if reject
            buffer << "CLIENT_ERROR: File declared in processed_templates does not exist and will not be rendered: #{erb_file}"
          end

          reject
        end

        render_erbs(env, erbs)

        buffer
      end

      #  cartridge_action(cartridge, action, software_version, render_erbs) -> buffer
      #
      #  Returns the results from calling a cartridge's action script.
      #  Includes <code>--version</code> if provided.
      #  Raises exception if script fails
      #
      #   stdout = cartridge_action(cartridge_obj)
      def cartridge_action(cartridge, action, software_version, render_erbs=false)
        logger.info "Running #{action} for #{@container.uuid}/#{cartridge.directory}"

        cartridge_home = PathUtils.join(@container.container_dir, cartridge.directory)
        action         = PathUtils.join(cartridge_home, 'bin', action)
        return "" unless File.exists? action

        # Cache system + scaled env vars + user_vars
        app_env            = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
        # Cache system env vars
        gear_env_home      = PathUtils.join(@container.container_dir, '.env')
        gear_env           = Utils::Environ.load(gear_env_home)
        # Cache user env vars
        user_env_home      = PathUtils.join(gear_env_home, 'user_vars')
        user_env           = Utils::Environ.load(user_env_home)
        cartridge_env_home = PathUtils.join(cartridge_home, 'env')
        cartridge_env      = Utils::Environ.load(cartridge_env_home)

        user_env.delete_if { |name, _| name != 'OPENSHIFT_SECRET_TOKEN' and gear_env.has_key?(name) }
        cartridge_env.delete('PATH')
        cartridge_env      = app_env.merge(cartridge_env).merge(user_env)
        if render_erbs
          erbs = Dir.glob(cartridge_env_home + '/*.erb', File::FNM_DOTMATCH).select { |f| File.file?(f) }
          render_erbs(cartridge_env, erbs)

          cartridge_env = Utils::Environ.load(cartridge_env_home)
          cartridge_env.delete('PATH')
          cartridge_env = app_env.merge(cartridge_env).merge(user_env)
        end

        action << " --version #{software_version}"
        out, _, _ = @container.run_in_container_context(action,
                                                        env:                 cartridge_env,
                                                        chdir:               cartridge_home,
                                                        timeout:             @hourglass.remaining,
                                                        expected_exitstatus: 0)
        logger.info("Ran #{action} for #{@container.uuid}/#{cartridge.directory}\n#{Runtime::Utils.sanitize_credentials(out)}")
        out
      end

      # render_erbs(program environment as a hash, erbs) -> nil
      #
      # Run <code>erb</code> against each template file submitted
      #
      #   v2_cart_model.render_erbs({HOMEDIR => '/home/no_place_like'}, ['/var/lib/openshift/user/cart/foo.erb', ...])
      def render_erbs(env, erbs)
        erbs.each do |file|
          begin
            @container.run_in_container_context(%Q{/usr/bin/oo-erb -S 2 -- #{file} > #{file.chomp('.erb')}},
                                                env:                 env,
                                                chdir:               @container.container_dir,
                                                timeout:             @hourglass.remaining,
                                                expected_exitstatus: 0)
          rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
            logger.info("Failed to render ERB #{file}: #{e.stderr}")
          else
            begin
              File.delete(file)
            rescue Errno::ENOENT
              # already gone for some reason; ignore it
            end
          end
        end
        nil
      end

      # cartridge_teardown(cartridge_name, remove_cartridge_dir) -> buffer
      #
      # Returns the output from calling the cartridge's teardown script.
      #  Raises exception if script fails
      #
      # stdout = cartridge_teardown('php-5.3')
      def cartridge_teardown(cartridge_name, remove_cartridge_dir=true)
        cartridge_home = PathUtils.join(@container.container_dir, cartridge_name)
        env            = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir, cartridge_home)
        teardown       = PathUtils.join(cartridge_home, 'bin', 'teardown')

        return "" unless File.exists? teardown
        return "#{teardown}: is not executable\n" unless File.executable? teardown

        # FIXME: Will anyone retry if this reports error, or should we remove from disk no matter what?
        buffer, err, _ = @container.run_in_container_context(teardown,
                                                             env:                 env,
                                                             chdir:               cartridge_home,
                                                             timeout:             @hourglass.remaining,
                                                             expected_exitstatus: 0)

        buffer << err

        FileUtils.rm_r(cartridge_home) if remove_cartridge_dir
        logger.info("Ran teardown for #{@container.uuid}/#{cartridge_name}")
        buffer
      end

      # Expose an endpoint for a cartridge through the port proxy.
      #
      # Returns nil on success, or raises an exception if any errors occur: all errors
      # here are considered fatal.
      def create_public_endpoint(cartridge, endpoint, private_ip)
        public_port = @container.create_public_endpoint(private_ip, endpoint.private_port)
        @container.add_env_var(endpoint.public_port_name, public_port)

        logger.info("Created public endpoint for cart #{cartridge.name} in gear #{@container.uuid}: "\
        "[#{endpoint.public_port_name}=#{public_port}]")
      end

      def list_proxy_mappings
        proxied_ports = []
        gear_env      = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
        each_cartridge do |cartridge|
          cartridge.endpoints.each do |endpoint|
            next if gear_env[endpoint.public_port_name].nil?
            proxied_ports << {
                :private_ip_name  => endpoint.private_ip_name,
                :public_port_name => endpoint.public_port_name,
                :private_ip       => gear_env[endpoint.private_ip_name],
                :private_port     => endpoint.private_port,
                :proxy_port       => gear_env[endpoint.public_port_name],
            }
          end
        end
        proxied_ports
      end

      # Allocates and assigns private IP/port entries for a cartridge
      # based on endpoint metadata for the cartridge.
      #
      # Returns nil on success, or raises an exception if any errors occur: all errors
      # here are considered fatal.
      def create_private_endpoints(cartridge)
        raise "Cartridge is required" unless cartridge
        return unless cartridge.endpoints && cartridge.endpoints.length > 0

        logger.info "Creating #{cartridge.endpoints.length} private endpoints for #{@container.uuid}/#{cartridge.directory}"

        env           = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir, PathUtils.join(@container.container_dir, cartridge.directory))
        allocated_ips = {}
        allocated_endpoints = []

        cartridge.endpoints.each do |endpoint|
          # Reuse previously allocated IPs of the same name. When recycling
          # an IP, double-check that it's not bound to the target port, and
          # bail if it's unexpectedly bound.
          unless allocated_ips.has_key?(endpoint.private_ip_name)
            if env.has_key?(endpoint.private_ip_name)
              allocated_ips[endpoint.private_ip_name] = env[endpoint.private_ip_name]
            else
              # Allocate a new IP for the endpoint
              private_ip = find_open_ip(endpoint.private_port)

              if private_ip.nil?
                raise "No IP was available to create endpoint for cart #{cartridge.name} in gear #{@container.uuid}: "\
                "#{endpoint.private_ip_name}(#{endpoint.private_port})"
              end

              @container.add_env_var(endpoint.private_ip_name, private_ip)

              allocated_ips[endpoint.private_ip_name] = private_ip
            end
          end

          private_ip = allocated_ips[endpoint.private_ip_name]

          next if env[endpoint.private_port_name]

          allocated_endpoints << endpoint

          @container.add_env_var(endpoint.private_port_name, endpoint.private_port)

          # Create the environment variable for WebSocket Port if it is specified
          # in the manifest.
          if endpoint.websocket_port_name && endpoint.websocket_port
            @container.add_env_var(endpoint.websocket_port_name, endpoint.websocket_port)
          end

          logger.info("Created private endpoint for cart #{cartridge.name} in gear #{@container.uuid}: "\
          "[#{endpoint.private_ip_name}=#{private_ip}, #{endpoint.private_port_name}=#{endpoint.private_port}]")

          # Expose the public endpoint if ssl_to_gear option is set
          if endpoint.options and endpoint.options["ssl_to_gear"]
            logger.info("ssl_to_gear option set for the endpoint")
            create_public_endpoint(cartridge, endpoint, private_ip)
          end
        end

        # Validate all the allocations to ensure they aren't already bound. Batch up the initial check
        # for efficiency, then do individual checks to provide better reporting before we fail.
        address_list = allocated_endpoints.map { |e| {ip: allocated_ips[e.private_ip_name], port: e.private_port} }
        if !address_list.empty? && @container.addresses_bound?(address_list, @hourglass)
          failures = ''
          allocated_endpoints.each do |endpoint|
            if @container.address_bound?(allocated_ips[endpoint.private_ip_name], endpoint.private_port, @hourglass, true)
              failures << "#{endpoint.private_ip_name}(#{endpoint.private_port})=#{allocated_ips[endpoint.private_ip_name]};"
            end
          end
          raise "Failed to create the following private endpoints due to existing process bindings: #{failures}" unless failures.empty?
        end
      end

      def delete_private_endpoints(cartridge)
        logger.info "Deleting private endpoints for #{@container.uuid}/#{cartridge.directory}"

        cartridge.endpoints.each do |endpoint|
          @container.remove_env_var(endpoint.private_ip_name)
          @container.remove_env_var(endpoint.private_port_name)
        end

        logger.info "Deleted private endpoints for #{@container.uuid}/#{cartridge.directory}"
      end

      def delete_private_endpoint(cartridge, endpoint, remove_private_ip=false)
        logger.info "Deleting private endpoint #{endpoint.private_ip_name}:#{endpoint.private_port_name} for #{@container.uuid}/#{cartridge.directory}"

        @container.remove_env_var(endpoint.private_ip_name) if remove_private_ip
        @container.remove_env_var(endpoint.private_port_name)
        disconnect_frontend_for_endpoint(cartridge, endpoint)

        logger.info "Deleted private endpoint #{endpoint.private_ip_name}:#{endpoint.private_port_name} for #{@container.uuid}/#{cartridge.directory}"
      end

      # Finds the next IP address available for binding of the given port for
      # the current gear user. The IP is assumed to be available only if the IP is
      # not already associated with an existing endpoint defined by any cartridge within the gear.
      #
      # Returns a string IP address in dotted-quad notation if one is available
      # for the given port, or returns nil if IP is available.
      def find_open_ip(port)
        allocated_ips = get_allocated_private_ips
        logger.debug("IPs already allocated for #{port} in gear #{@container.uuid}: #{allocated_ips}")

        open_ip = nil

        for host_ip in 1..127
          candidate_ip = @container.get_ip_addr(host_ip)

          # Skip the IP if it's already assigned to an endpoint
          next if allocated_ips.include?(candidate_ip)

          open_ip = candidate_ip
          break
        end

        open_ip
      end

      # Returns an array containing all currently allocated endpoint private
      # IP addresses assigned to carts within the current gear, or an empty
      # array if none are currently defined.
      def get_allocated_private_ips
        env = ::OpenShift::Runtime::Utils::Environ::for_gear(@container.container_dir)

        allocated_ips = []

        # Collect all existing endpoint IP allocations
        process_cartridges do |cart_path|
          cart_dir = File.basename(cart_path)
          cart     = get_cartridge_from_directory(cart_dir)

          cart.endpoints.each do |endpoint|
            # TODO: If the private IP variable exists but the value isn't in
            # the environment, what should happen?
            ip = env[endpoint.private_ip_name]
            allocated_ips << ip unless ip == nil
          end
        end

        allocated_ips
      end

      def disconnect_frontend_for_endpoint(cartridge, endpoint)
        mappings = []
        endpoint.mappings.each do |mapping|
          mappings << mapping.frontend
        end

        logger.info("Disconnecting frontend mapping for #{@container.uuid}/#{cartridge.name}: #{mappings.inspect}")
        unless mappings.empty?
          FrontendHttpServer.new(@container).disconnect(*mappings)
        end
      end

      # disconnect cartridge from frontend proxy
      #
      # This is only called when a cartridge is removed from a cartridge not a gear delete
      def disconnect_frontend(cartridge)
        gear_env       = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)

        mappings = []
        cartridge.endpoints.each do |endpoint|
          endpoint.mappings.each do |mapping|
            mappings << mapping.frontend
          end
        end

        logger.info("Disconnecting frontend mapping for #{@container.uuid}/#{cartridge.name}: #{mappings.inspect}")
        unless mappings.empty?
          fe_server =  FrontendHttpServer.new(@container)
          fe_server.disconnect(*mappings)
        end
      end

      def connect_frontend(cartridge, rebuild=false)
        frontend       = FrontendHttpServer.new(@container)
        gear_env       = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
        web_proxy_cart = web_proxy
        app_dns        = gear_env["OPENSHIFT_APP_DNS"].to_s.downcase

        output = ""
        begin
          # TODO: exception handling
          cartridge.endpoints.each do |endpoint|
            endpoint.mappings.each do |mapping|
              private_ip  = gear_env[endpoint.private_ip_name]
              backend_uri = "#{private_ip}:#{endpoint.private_port}#{mapping.backend}"
              options     = mapping.options ||= {}

              if endpoint.websocket_port
                options["websocket_port"] = endpoint.websocket_port
              end

              options["protocols"]=endpoint.protocols

              # Make sure that the mapping does not collide with the default web_proxy mapping
              if mapping.frontend == "" and not cartridge.web_proxy? and web_proxy_cart and not rebuild
                logger.info("Skipping default mapping as web proxy owns it for the application")
                next
              end

              # Only web proxy cartridges can override the default mapping
              if mapping.frontend == "" && (!cartridge.web_proxy?) && (cartridge.name != primary_cartridge.name)
                logger.info("Skipping default mapping as primary cartridge owns it for the application")
                next
              end

              # If the mapping contains the option ssl_to_gear, create an environment
              if options["ssl_to_gear"]
                @container.add_env_var("SSL_TO_GEAR", 1)
                logger.debug("Adding SSL_TO_GEAR env var")
              end
              logger.info("Connecting frontend mapping for #{@container.uuid}/#{cartridge.name}: "\
                      "[#{mapping.frontend}] => [#{backend_uri}] with options: #{mapping.options}")
              reported_urls = frontend.connect(mapping.frontend, backend_uri, options)
              if cartridge.web_proxy? && frontend.fqdn != app_dns
                # secondary web-proxy gear should have app DNS routed too
                frontend.add_alias(app_dns)
              end
              if reported_urls
                reported_urls.each do |url|
                  outstr = "Cartridge #{cartridge.name} endpoint #{endpoint.private_port_name} is exposed at URL #{url}"

                  # Add env variable for the public port mapping.
                  @container.add_env_var(endpoint.public_port_name, url[/(\d+)$/])
                  if endpoint.description
                    outstr << " for #{endpoint.description}"
                  end
                  output << "CLIENT_RESULT: #{outstr}\n"
                  output << "NOTIFY_MAPPING_CREATE #{outstr}\n"
                end
              end
            end
          end
        rescue Exception => e
          logger.warn("V2CartModel#connect_frontend: #{e.message}\n#{e.backtrace.join("\n")}")
          raise
        end
        output
      end

      # Run code block against each cartridge in gear
      #
      # @param  [block]  Code block to process cartridge
      # @yields [String] cartridge directory for each cartridge in gear
      def process_cartridges(cartridge_dir = nil) # : yields cartridge_path
        if cartridge_dir
          cart_dir = PathUtils.join(@container.container_dir, cartridge_dir)
          yield cart_dir if File.exist?(cart_dir)
          return
        end

        Dir[PathUtils.join(@container.container_dir, "*")].each do |cart_dir|
          next if File.symlink?(cart_dir) || !File.exist?(PathUtils.join(cart_dir, "metadata", "manifest.yml"))
          yield cart_dir
        end if @container.container_dir and File.exist?(@container.container_dir)
      end

      def do_control(action, cartridge, options={})
        case cartridge
          when String
            cartridge_dir = cartridge_directory(cartridge)
          when Manifest
            cartridge_dir = cartridge.directory
          else
            raise "Unsupported cartridge argument type: #{cartridge.class}"
        end

        options[:cartridge_dir] = cartridge_dir

        do_control_with_directory(action, options)
      end

      def short_name_from_full_cart_name(pub_cart_name)
        raise ArgumentError.new('pub_cart_name cannot be nil') unless pub_cart_name

        return pub_cart_name if pub_cart_name.index('-').nil?

        tokens = pub_cart_name.split('-')
        tokens.pop
        tokens.join('-')
      end

      # Let a cart perform some action when another cart is being removed
      # Today, it is used to cleanup environment variables
      def unsubscribe(cart_name, pub_cart_name)
        env_dir_path = PathUtils.join(@container.container_dir, '.env', short_name_from_full_cart_name(pub_cart_name))
        FileUtils.rm_rf(env_dir_path)
      end

      def set_connection_hook_env_vars(cart_name, pub_cart_name, args)
        logger.info("Setting env vars for #{cart_name} from #{pub_cart_name}")
        logger.info("ARGS: #{args.inspect}")

        env_dir_path = PathUtils.join(@container.container_dir, '.env', short_name_from_full_cart_name(pub_cart_name))
        FileUtils.mkpath(env_dir_path)

        envs = {}

        # Skip the first three arguments and jump to gear => "k1=v1\nk2=v2\n" hash map
        pairs = args[3].values[0].split("\n")

        pairs.each do |pair|
          next if not pair.include? '='

          k, v    = pair.strip.split("=")
          envs[k] = v
        end

        write_environment_variables(env_dir_path, envs, false)
      end

      # Convert env var hook arguments to shell arguments
      # TODO: document expected form of args
      def convert_to_shell_arguments(args)
        new_args = []
        args[3].each do |k, v|
          vstr = v.split("\n").map { |p| p + ";" }.join(' ')
          new_args.push "'#{k}'='#{vstr}'"
        end
        (args[0, 2] << ::Shellwords::shellescape(new_args.join(' '))).join(' ')
      end

      # :call-seq:
      #    V2CartridgeModel.new(...).connector_execute(cartridge_name, connection_type, connector, args) => String
      #
      def connector_execute(cart_name, pub_cart_name, connection_type, connector, args)
        raise ArgumentError.new('cart_name cannot be nil') unless cart_name

        cartridge    = get_cartridge(cart_name)
        env          = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir, PathUtils.join(@container.container_dir, cartridge.directory))
        env_var_hook = connection_type.start_with?("ENV:") && pub_cart_name

        # Special treatment for env var connection hooks
        if env_var_hook
          set_connection_hook_env_vars(cart_name, pub_cart_name, args)
          args = convert_to_shell_arguments(args)
        end

        conn = Runtime::PubSubConnector.new connection_type, connector

        if conn.reserved?
          begin
            return send(conn.action_name, cartridge, args)
          rescue NoMethodError => e
            logger.debug "#{e.message}; falling back to script"
          end
        end

        cartridge_home = PathUtils.join(@container.container_dir, cartridge.directory)
        script         = PathUtils.join(cartridge_home, 'hooks', conn.name)

        unless File.executable?(script)
          if env_var_hook
            return "Set environment variables successfully"
          else
            msg = "ERROR: action '#{connector}' not found."
            raise ::OpenShift::Runtime::Utils::ShellExecutionException.new(msg, 127, msg)
          end
        end

        command      = script << " " << args
        out, err, rc = @container.run_in_container_context(command,
                                                           env:     env,
                                                           chdir:   cartridge_home,
                                                           timeout: @hourglass.remaining)
        if 0 == rc
          logger.info("(#{rc})\n------\n#{Runtime::Utils.sanitize_credentials(out)}\n------)")
          return out
        end

        logger.info("ERROR: (#{rc})\n------\n#{Runtime::Utils.sanitize_credentials(out)}\n------)")
        raise ::OpenShift::Runtime::Utils::ShellExecutionException.new(
                  "Control action '#{connector}' returned an error. rc=#{rc}\n#{out}", rc, out, err)
      end

      # :call-seq:
      #   V2CartridgeModel.new(...).do_control_with_directory(action, options)  -> output
      #   V2CartridgeModel.new(...).do_control_with_directory(action)           -> output
      #
      # Call action on cartridge +control+ script. Run all pre/post hooks if found.
      #
      # +options+: hash
      #   :cartridge_dir => path             : Process all cartridges (if +nil+) or the provided cartridge
      #   :pre_action_hooks_enabled => true  : Whether to process repo action hooks before +action+
      #   :post_action_hooks_enabled => true : Whether to process repo action hooks after +action+
      #   :prefix_action_hooks => true       : If +true+, action hook names are automatically prefixed with
      #                                        'pre' and 'post' depending on their execution order.
      #   :out                               : An +IO+ object to which control script STDOUT should be directed. If
      #                                        +nil+ (the default), output is logged.
      #   :err                               : An +IO+ object to which control script STDERR should be directed. If
      #                                        +nil+ (the default), output is logged.
      #   :env_overrides                     : environment variable overrides
      #
      def do_control_with_directory(action, options={})
        cartridge_dir             = options[:cartridge_dir]
        pre_action_hooks_enabled  = options.has_key?(:pre_action_hooks_enabled) ? options[:pre_action_hooks_enabled] : true
        post_action_hooks_enabled = options.has_key?(:post_action_hooks_enabled) ? options[:post_action_hooks_enabled] : true
        prefix_action_hooks       = options.has_key?(:prefix_action_hooks) ? options[:prefix_action_hooks] : true

        logger.debug { "#{@container.uuid} #{action} against '#{cartridge_dir}'" }
        buffer       = ''
        # Cache system + scaled env vars + user_vars
        app_env     = ::OpenShift::Runtime::Utils::Environ.for_gear(@container.container_dir)
        app_env.merge!(options[:env_overrides]) if options[:env_overrides]
        action_hooks = PathUtils.join(app_env['OPENSHIFT_REPO_DIR'], %w{.openshift action_hooks})

        # Cache system env vars
        gear_env_home = PathUtils.join(@container.container_dir, '.env')
        gear_env      = Utils::Environ.load(gear_env_home)
        # Cache user env vars
        user_env_home = PathUtils.join(gear_env_home, 'user_vars')
        user_env      = Utils::Environ.load(user_env_home)

        # Don't overwrite gear vars when merging cache
        user_env.delete_if { |name, _| name != 'OPENSHIFT_SECRET_TOKEN' and gear_env.has_key?(name) }

        if pre_action_hooks_enabled
          pre_action_hook = prefix_action_hooks ? "pre_#{action}" : action
          hook_buffer     = do_action_hook(pre_action_hook, app_env, options)
          buffer << hook_buffer if hook_buffer.is_a?(String)
        end

        process_cartridges(cartridge_dir) { |path|
          # Make sure this cartridge's env directory overrides that of other cartridge envs
          cartridge_local_env = ::OpenShift::Runtime::Utils::Environ.load(PathUtils.join(path, 'env'))
          cartridge_local_env.delete('PATH')

          ident                            = cartridge_local_env.keys.grep(/^OPENSHIFT_.*_IDENT/)
          _, software, software_version, _ = Runtime::Manifest.parse_ident(cartridge_local_env[ident.first])
          hooks                            = cartridge_hooks(action_hooks, action, software, software_version)

          cartridge_env = app_env.merge(cartridge_local_env).merge(user_env)
          control = PathUtils.join(path, 'bin', 'control')

          command = []
          command << hooks[:pre] unless hooks[:pre].empty?
          if File.executable? control
            if options[:args]
              args = Shellwords::shellescape(options[:args])
            end
            command << "#{control} #{action} #{args}"
          end
          command << hooks[:post] unless hooks[:post].empty?

          unless command.empty?
            command = ['set -e'] | command

            out, err, rc = @container.run_in_container_context(command.join('; '),
                                                               env:     cartridge_env,
                                                               chdir:   path,
                                                               timeout: @hourglass.remaining,
                                                               out:     options[:out],
                                                               err:     options[:err])

            buffer << out if out.is_a?(String)
            buffer << err if err.is_a?(String)

            raise ::OpenShift::Runtime::Utils::ShellExecutionException.new(
                      "CLIENT_ERROR: Failed to execute: 'control #{action}' for #{path}", rc, out, err
                  ) if rc != 0
          end
        }

        if post_action_hooks_enabled
          post_action_hook = prefix_action_hooks ? "post_#{action}" : action
          hook_buffer      = do_action_hook(post_action_hook, app_env, options)
          buffer << hook_buffer if hook_buffer.is_a?(String)
        end

        buffer
      end

      ##
      # Executes the named +action+ from the user repo +action_hooks+ directory and returns the
      # stdout of the execution, or raises a +ShellExecutionException+ if the action returns a
      # non-zero return code.
      #
      # All hyphens in the +action+ will be replaced with underscores.
      def do_action_hook(action, env, options)
        action = action.gsub(/-/, '_')

        action_hooks_dir = PathUtils.join(env['OPENSHIFT_REPO_DIR'], %w{.openshift action_hooks})
        action_hook      = PathUtils.join(action_hooks_dir, action)
        buffer           = ''

        if File.executable?(action_hook)
          out, err, rc = @container.run_in_container_context(action_hook,
                                                             env:     env,
                                                             chdir:   @container.container_dir,
                                                             timeout: @hourglass.remaining,
                                                             out:     options[:out],
                                                             err:     options[:err])
          raise ::OpenShift::Runtime::Utils::ShellExecutionException.new(
                    "CLIENT_ERROR: Failed to execute action hook '#{action}' for #{@container.uuid} application #{@container.application_name}",
                    rc, out, err
                ) if rc != 0
        elsif File.exists?(action_hook)
          hook = action_hook.split("/")[-3..-1].join("/")
          notice = "NOTE: The #{hook} hook is not executable, to make it executable:\n"
          notice += "      On Windows run:   git update-index --chmod=+x #{hook}\n"
          notice += "      On Linux/OSX run: chmod +x #{hook}\n"
          # FIXME: This works for all action_hooks. Putting the notice into
          #        'buffer' works only for prepare/build but it is silenced for
          #        pre/post_* hooks
          $stdout.puts notice
        end

        buffer << out if out.is_a?(String)
        buffer << err if err.is_a?(String)

        buffer
      end

      def cartridge_hooks(action_hooks, action, name, version)
        hooks = {pre: [], post: []}

        hooks.each_key do |key|
          new_hook = PathUtils.join(action_hooks, "#{key}_#{action}_#{name}")
          old_hook = PathUtils.join(action_hooks, "#{key}_#{action}_#{name}-#{version}")

          hooks[key] << "source #{new_hook}" if File.exist? new_hook
          hooks[key] << "source #{old_hook}" if File.exist? old_hook
        end
        hooks
      end

      ##
      # Shuts down the gear by running the cartridge +stop+ control action for each cartridge
      # in the gear.
      #
      # +options+: hash
      #   :user_initiated => [boolean]    : Indicates whether the operation was user initated.
      #                                     Default is +true+.
      #   :exclude_web_proxy => [boolean] : Indicates whether to exclude stopping the web proxy cartridge.
      #                                     Default is +false+
      #   :out                            : An +IO+ object to which control script STDOUT should be directed. If
      #                                     +nil+ (the default), output is logged.
      #   :err                            : An +IO+ object to which control script STDERR should be directed. If
      #                                     +nil+ (the default), output is logged.
      #
      # Returns the combined output of all +stop+ action executions as a +String+.
      def stop_gear(options={})
        options[:user_initiated] = true if not options.has_key?(:user_initiated)

        buffer = ''

        each_cartridge do |cartridge|
          next if options[:exclude_web_proxy] and cartridge.web_proxy?

          buffer << stop_cartridge(cartridge, options)
        end

        buffer
      end

      ##
      # Starts up the gear by running the cartridge +start+ control action for each
      # cartridge in the gear.
      #
      # By default, all cartridges in the gear are started. The selection of cartridges
      # to be started is configurable via +options+.
      #
      # +options+: hash
      #   :primary_only   => [boolean]    : If +true+, only the primary cartridge will be started.
      #                                     Mutually exclusive with +secondary_only+.
      #   :secondary_only => [boolean]    : If +true+, all cartridges except the primary cartridge
      #                                     will be started. Mutually exclusive with +primary_only+.
      #   :user_initiated => [boolean]    : Indicates whether the operation was user initated.
      #                                     Default is +true+.
      #   :exclude_web_proxy => [boolean] : Indicates whether to exclude stopping the web proxy cartridge.
      #                                     Default is +false+
      #   :out                            : An +IO+ object to which control script STDOUT should be directed. If
      #                                     +nil+ (the default), output is logged.
      #   :err                            : An +IO+ object to which control script STDERR should be directed. If
      #                                     +nil+ (the default), output is logged.
      #
      # Returns the combined output of all +start+ action executions as a +String+.
      def start_gear(options={})
        options[:user_initiated] = true if not options.has_key?(:user_initiated)

        if options[:primary_only] && options[:secondary_only]
          raise ArgumentError.new('The primary_only and secondary_only options are mutually exclusive options')
        end

        buffer = ''

        if options[:primary_only] || options[:secondary_only]
          each_cartridge do |cartridge|
            next if options[:primary_only] and cartridge.name != primary_cartridge.name
            next if options[:secondary_only] and cartridge.name == primary_cartridge.name
            next if options[:exclude_web_proxy] and cartridge.web_proxy?

            buffer << start_cartridge('start', cartridge, options)
          end
        else
          buffer << start_gear(options.merge({secondary_only: true}))
          buffer << start_gear(options.merge({primary_only: true}))
        end
        buffer
      end

      ##
      # Restarts catridges in the gear by running the cartridge +restart+ control action for each
      # cartridge in the gear.
      #
      # By default, all cartridges in the gear are restarted. The selection of cartridges
      # to be restarted is configurable via +options+.
      #
      # +options+: hash
      #   :primary_only   => [boolean]    : If +true+, only the primary cartridge will be restarted.
      #                                     Mutually exclusive with +secondary_only+.
      #   :secondary_only => [boolean]    : If +true+, all cartridges except the primary cartridge
      #                                     will be restarted. Mutually exclusive with +primary_only+.
      #   :user_initiated => [boolean]    : Indicates whether the operation was user initated.
      #                                     Default is +true+.
      #   :exclude_web_proxy => [boolean] : Indicates whether to exclude restarting the web proxy cartridge.
      #                                     Default is +false+
      #   :out                            : An +IO+ object to which control script STDOUT should be directed. If
      #                                     +nil+ (the default), output is logged.
      #   :err                            : An +IO+ object to which control script STDERR should be directed. If
      #                                     +nil+ (the default), output is logged.
      #
      # Returns the combined output of all +restart+ action executions as a +String+.
      def restart_gear(options={})
        options[:user_initiated] = true if not options.has_key?(:user_initiated)

        if options[:primary_only] && options[:secondary_only]
          raise ArgumentError.new('The primary_only and secondary_only options are mutually exclusive options')
        end

        buffer = ''

        if options[:primary_only] || options[:secondary_only]
          each_cartridge do |cartridge|
            next if options[:primary_only] and cartridge.name != primary_cartridge.name
            next if options[:secondary_only] and cartridge.name == primary_cartridge.name
            next if options[:exclude_web_proxy] and cartridge.web_proxy?

            buffer << start_cartridge('restart', cartridge, options)
          end
        else
          buffer << restart_gear(options.merge({secondary_only: true}))
          buffer << restart_gear(options.merge({primary_only: true}))
        end
        buffer
      end

      ##
      # Starts a cartridge.
      #
      # Both application state and the stop lock are managed during the operation. If start
      # of the primary cartridge is invoked and +user_initiated+ is true, the stop lock is
      # created.
      #
      # +type+      : Type of start [start, restart, reload]
      # +cartridge+ : A +Cartridge+ instance or +String+ name of a cartridge.
      # +options+   : hash
      #   :user_initiated => [boolean]  : Indicates whether the operation was user initated.
      #                                   Default is +true+.
      #   :hot_deploy => [boolean]      : If +true+ and if +cartridge+ is the primary cartridge in the gear, the
      #                                   gear state will be set to +STARTED+ but the actual cartridge start operation
      #                                   will be skipped. Non-primary cartridges will be skipped with no state change.
      #                                   Default is +false+.
      #   :out                          : An +IO+ object to which control script STDOUT should be directed. If
      #                                   +nil+ (the default), output is logged.
      #   :err                          : An +IO+ object to which control script STDERR should be directed. If
      #                                   +nil+ (the default), output is logged.
      #
      # Returns the output of the operation as a +String+ or raises a +ShellExecutionException+
      # if the cartridge script fails.
      def start_cartridge(type, cartridge, options={})
        options[:user_initiated] = true if not options.has_key?(:user_initiated)
        options[:hot_deploy] = false if not options.has_key?(:hot_deploy)

        cartridge = get_cartridge(cartridge) if cartridge.is_a?(String)

        if not options[:user_initiated] and stop_lock?
          return "Not starting cartridge #{cartridge.name} because the application was explicitly stopped by the user"
        end

        if cartridge.name == primary_cartridge.name
          if options[:user_initiated]
            FileUtils.rm_f(stop_lock)

            # Unidle the application, preferring to use the privileged operation if possible
            frontend = FrontendHttpServer.new(@container)
            if Process.uid == @container.uid
              frontend.unprivileged_unidle
            else
              frontend.unidle
            end

          end
          @state.value = State::STARTED
        end

        if options[:hot_deploy]
          output = "Not starting cartridge #{cartridge.name} because hot deploy is enabled"
          options[:out].puts(output) if options[:out]
          return output
        end

        do_control(type, cartridge, options)
      end

      ##
      # Stops a cartridge.
      #
      # Both application state and the stop lock are managed during the operation. If stop
      # of the primary cartridge is invoked and +user_initiated+ is true, the stop lock
      # is removed.
      #
      # +cartridge+ : A +Cartridge+ instance or +String+ name of a cartridge.
      # +options+   : hash
      #   :user_initiated => [boolean]  : Indicates whether the operation was user initated.
      #                                   Default is +true+.
      #   :hot_deploy => [boolean]      : If +true+, the stop operation is skipped for all cartridge types,
      #                                   the gear state is not modified, and the stop lock is never created.
      #                                   Default is +false+.
      #   :out                          : An +IO+ object to which control script STDOUT should be directed. If
      #                                   +nil+ (the default), output is logged.
      #   :err                          : An +IO+ object to which control script STDERR should be directed. If
      #                                   +nil+ (the default), output is logged.
      #
      # Returns the output of the operation as a +String+ or raises a +ShellExecutionException+
      # if the cartridge script fails.
      def stop_cartridge(cartridge, options={})
        options[:user_initiated] = true if not options.has_key?(:user_initiated)
        options[:hot_deploy] = false if not options.has_key?(:hot_deploy)

        cartridge = get_cartridge(cartridge) if cartridge.is_a?(String)

        if options[:hot_deploy]
          output = "Not stopping cartridge #{cartridge.name} because hot deploy is enabled"
          options[:out].puts(output) if options[:out]
          return output
        end

        if not options[:user_initiated] and stop_lock?
          return "Not stopping cartridge #{cartridge.name} because the application was explicitly stopped by the user\n"
        end

        if cartridge.name == primary_cartridge.name
          create_stop_lock if options[:user_initiated]
          @state.value = State::STOPPED
        end

        do_control('stop', cartridge, options)
      end

      ##
      # Writes the +stop_lock+ file and changes its ownership to the gear user.
      def create_stop_lock(reason = nil)
        unless stop_lock?
          File.open(stop_lock, File::CREAT|File::TRUNC|File::WRONLY, 0644) do |f|
            f.write(reason) if reason
          end
          @container.set_rw_permission(stop_lock)
        end
      end

      def has_repository?
        ApplicationRepository.new(@container).exists?
      end

      private
      ## special methods that are handled especially by the platform

      def empty_repository?
        ApplicationRepository.new(@container).empty?
      end

      def populate_repository?(cartridge, template_git_url)
        # we should populate the gear repo if we have a deployable cartridge
        # or if we have a standalone web proxy and a git url for a template was provided
        (cartridge.deployable? or (standalone_web_proxy? and template_git_url))
      end
    end
  end
end
