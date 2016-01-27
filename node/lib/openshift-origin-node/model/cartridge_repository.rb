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

=begin
Cartridge Repository--

* 1 per Node
* Index used by Node to find cartridges to install
* A cartridge version can only safely be removed from the Repository
  if it is not being used in any gear. A new version will only impact
  new instances of the cartridge being installed.
  * A cartridge instance is updated to a new version by:
    - remove old version/add new version from the gear
    - migration, compatible change old to new
    - migration/setup, incompatible change old to new

* Default software version is greatest Version element
* Default cartridge version is greatest Cartridge-Version element

In-Memory Index (missing keys will assume default)
{cartridge name}, {software version}, {cartridge version} -> Cartridge obj

Cartridge Repository (1 per Node)
CARTRIDGE_REPO_DIR/{cartridge vendor}-{cartridge name}
    +- {cartridge version 0}
    |  +- metadata
    |  |  +- manifest.yml
    |  +- ...(file tree)
    +- {cartridge version 1}
    |  +- metadata
    |  |  +- manifest.yml
    |  +- ... (file tree)
    +- {cartridge version 2}
    |  +- ...


Gear
GEAR_BASE_DIR/{cartridge vendor}-{cartridge name}
    +- metadata
    |  +- manifest.yml
    +- ... (file tree)
GEAR_BASE_DIR/local-{custom cartridge name}
    +- metadata
    |  +- manifest.yml
    +- ... (file tree)
=end

require 'openshift-origin-common/utils/path_utils'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-common/models/manifest'
require 'pathname'
require 'singleton'
require 'set'
require 'thread'
require 'open-uri'
require 'uri'
require 'rubygems/package'
require 'openssl'
require 'shellwords'


$OpenShift_CartridgeRepository_SEMAPHORE = Mutex.new

module OpenShift
  module Runtime
    # Singleton to provide management of cartridges installed on the system
    #
    class CartridgeRepository
      include Singleton
      include NodeLogger
      include Enumerable

      #FIXME: move to node.conf
      CARTRIDGE_REPO_DIR = '/var/lib/openshift/.cartridge_repository'

      # Filesystem path to where cartridges are installed
      attr_reader :path

      def initialize # :nodoc:
        @path = CARTRIDGE_REPO_DIR

        FileUtils.mkpath(@path) unless File.exist? @path
        clear
        load @path
      end

      # :call-seq:
      #   CartridgeRepository.instance.clear -> nil
      #
      # Clear all entries from the memory index. Nothing is removed from the disk.
      #
      #   CartridgeRepository.instance.clear #=> nil
      def clear
        @index = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
      end

      # :call-seq:
      #   CartridgeRepository.instance.load([directory path]) -> Fixnum
      #
      # Read cartridge manifests from the CARTRIDGE_REPO_DIR or the provided +directory+.
      #
      #   CartridgeRepository.instance.load("/var/lib/openshift/.cartridge_repository")  #=> 24
      def load(directory = nil)
        $OpenShift_CartridgeRepository_SEMAPHORE.synchronize do
          load_via_url = directory.nil?
          find_manifests(directory || @path) do |manifest_path|
            logger.debug { "Loading cartridge from #{manifest_path}" }

            if File.size(manifest_path) == 0
              logger.warn("Skipping load of #{manifest_path} because manifest appears to be corrupted")
              next
            end

            c = insert(Manifest.new(manifest_path, nil, :file, @path, load_via_url))
            logger.debug { "Loaded cartridge (#{c.cartridge_vendor}, #{c.name}, #{c.version}, #{c.cartridge_version})" }
          end
        end

        count
      end

      # :call-seq:
      #   CartridgeRepository.instance.select(vendor, name, version)                    -> Cartridge
      #   CartridgeRepository.instance.select(vendor, name, version, cartridge_version) -> Cartridge
      #   CartridgeRepository.instance[vendor, name, version]                           -> Cartridge
      #   CartridgeRepository.instance[vendor, name, version, cartridge_version]        -> Cartridge
      #
      # Select a software version for a cartridge from the repository.
      #
      # If you do not provide _cartridge_version_ then the latest is assumed, for _version_ and _cartridge_name_.
      #
      # Latest is determined from the _Version_ elements provided in the cartridge's manifest, when the cartridge is
      # loaded.
      #
      # Assuming PHP, 3.5 and 0.1 are all the latest each of these calls would return the same cartridge.
      #   CartridgeRepository.instance.select('redhat', 'php', '3.5', '0.1')  #=> Cartridge
      #   CartridgeRepository.instance.select('redhat', 'php', '3.5')         #=> Cartridge
      #   CartridgeRepository.instance['redhat', 'php', '3.5', '0.1']         #=> Cartridge
      #   CartridgeRepository.instance['redhat', 'php', '3.5']                #=> Cartridge
      #
      def select(vendor, name, version, cartridge_version = '_')
        unless exist?(vendor, name, version, cartridge_version)
          raise KeyError.new("key not found: (#{vendor}, #{name}, #{version}, #{cartridge_version})")
        end

        @index[vendor][name][version][cartridge_version]
      end

      alias [] select # :nodoc:

      # :call-seq:
      #   CartridgeRepository.instance.install(directory) -> Cartridge
      #
      # Copies a cartridge's source into the cartridge repository from a +directory+. The Cartridge will additionally
      # be indexed and available from a CartridgeRepository.instance
      #
      #   CartridgeRepository.instance.install('/usr/libexec/openshift/cartridges/openshift-origin-php')  #=> Cartridge
      def install(directory)
        raise ArgumentError.new("Illegal path to cartridge source: '#{directory}'") unless directory && File.directory?(directory)
        raise ArgumentError.new("Source cannot be: '#{@path}'") if directory == @path

        manifest_path = PathUtils.join(directory, 'metadata', 'manifest.yml')
        raise ArgumentError.new("Cartridge manifest.yml missing: '#{manifest_path}'") unless File.file?(manifest_path)

        entry = nil
        $OpenShift_CartridgeRepository_SEMAPHORE.synchronize do
          entry = insert(Manifest.new(manifest_path, nil, :file, @path))

          FileUtils.rm_r(entry.repository_path) if File.exist?(entry.repository_path)
          FileUtils.mkpath(entry.repository_path)

          source = Shellwords.escape(directory)
          # We specifically don't want --preserve=context because we want
          # the cartridge relabeled when it is copied into the cartridge
          # repository, and we don't want --preserve=xattr because that
          # implies --preserve=context on some filesystems.
          Utils.oo_spawn("shopt -s dotglob; /bin/cp --recursive --no-dereference --preserve=mode,ownership,timestamps,links #{source}/* #{entry.repository_path}",
                         expected_exitstatus: 0)
        end
        entry
      end

      # :call-seq:
      #   CartridgeRepository.instance.erase(vendor, name, version, cartridge_version) -> Cartridge
      #
      # Erase all software versions for the given cartridge version from the repository. This cannot be undone.
      #
      #   CartridgeRepository.instance.erase('redhat', 'php', '3.5', '1.0') #=> Cartridge
      def erase(vendor, name, version, cartridge_version, force = false)
        unless exist?(vendor, name, version, cartridge_version)
          raise KeyError.new("key not found: (#{vendor}, #{name}, #{version}, #{cartridge_version})")
        end

        if !force && installed_in_base_path?(name, version, cartridge_version)
          raise ArgumentError.new('Cannot erase cartridge installed in CARTRIDGE_BASE_PATH')
        end

        entry = nil
        $OpenShift_CartridgeRepository_SEMAPHORE.synchronize do
          # find a "template" entry
          entry = select(vendor, name, version, cartridge_version)

          entry.versions.each do |software_version|
            remove(vendor, name, software_version, cartridge_version)
          end

          FileUtils.rm_r(entry.repository_path)
          parent = Pathname.new(entry.repository_path).parent
          FileUtils.rm_r(parent.to_s) if 0 == parent.children.count
        end

        entry
      end

      def installed_in_base_path?(name, version, cartridge_version)
        config              = OpenShift::Config.new
        cartridge_base_path = config.get('CARTRIDGE_BASE_PATH')
        cartridge_path      = PathUtils.join(cartridge_base_path, name)

        unless File.exists?(cartridge_path)
          return false
        end

        manifest_path = PathUtils.join(cartridge_path, %w(metadata manifest.yml))

        unless File.exists?(manifest_path)
          return false
        end

        error = false

        begin
          manifest = Manifest.new(manifest_path, nil, :file)
        rescue OpenShift::InvalidElementError => e
          error = true
        rescue OpenShift::MissingElementError => e
          error = true
        end

        return (!error && manifest.versions.include?(version) && manifest.cartridge_version == cartridge_version)
      end

      # :call-seq:
      #   CartridgeRepository.instance.exist?(vendor, name, cartridge_version, version)  -> true or false
      #
      # Is there an entry in the repository for this tuple?
      #
      #   CartridgeRepository.instance.exist?('redhat', cobol', '2002', '1.0') #=> false
      def exist?(vendor, name, version, cartridge_version)
        @index.key?(vendor) &&
            @index[vendor].key?(name) &&
            @index[vendor][name].key?(version) &&
            @index[vendor][name][version].key?(cartridge_version)
      end

      # :call-seq:
      #   CartridgeRepository.instance.find_manifests(directory)
      #
      # Search the cartridge repository +directory+ sub-directories for cartridge manifest files
      #
      #   CartridgeRepository.instance.find_manifests(directory)
      def find_manifests(directory) # :nodoc: :yield: pathname
        raise ArgumentError.new("Illegal path to cartridge repository: '#{directory}'") unless File.directory?(directory)

        Dir.glob(PathUtils.join(directory, '*')).each do |path|
          next unless File.directory?(path)

          entries = Dir.entries(path)
          entries.delete_if { |e| e =~ /\A\.\.?\Z/ }
          next unless entries && !entries.empty?

          Manifest.sort_versions(entries).each do |version|
            filename = PathUtils.join(path, version, 'metadata', 'manifest.yml')
            yield filename if File.exist?(filename)
          end
        end
      end

      # :call-seq:
      #   CartridgeRepository.instance.remove(vendor, name, version, cartridge_version) -> Cartridge
      #
      # Remove index entry for this tuple, ensuring that default entries for the latest
      # cartridge version maintain integrity
      #
      #   CartridgeRepository.instance.remove('redhat', php', '5.3', '1.0') -> Cartridge
      def remove(vendor, name, version, cartridge_version) # :nodoc:
        recompute_cartridge_version = false

        unless exist?(vendor, name, version, cartridge_version)
          raise KeyError.new("key not found: (#{vendor}, #{name}, #{version}, #{cartridge_version})")
        end

        logger.debug "Removing (#{vendor}, #{name}, #{version}, #{cartridge_version}) from index"

        slice = @index[vendor][name]

        if latest_in_slice?(slice[version], cartridge_version)
          recompute_cartridge_version = true
        end

        slice[version].delete(cartridge_version)
        real_cart_versions = slice[version].keys
        real_cart_versions.delete('_')

        if real_cart_versions.empty?
          logger.debug("No more cartridge versions for (#{vendor}, #{name}, #{version}), deleting from index")
          slice.delete(version)
          recompute_cartridge_version = false

          if slice.empty?
            logger.debug "No more versions left for (#{vendor}, #{name}), deleting from index"
            @index[vendor].delete(name)
          end
        end

        if @index[vendor].key?(name) && recompute_cartridge_version
          latest_cartridge_version = latest_in_slice(slice[version])

          if latest_cartridge_version
            logger.debug("Resetting default for (#{vendor}, #{name}, #{version}) to #{latest_cartridge_version}")
            manifest                           = @index[vendor][name][version][latest_cartridge_version]
            @index[vendor][name][version]['_'] = manifest
          end
        end
      end


      # :call-seq:
      #   CartridgeRepository.instance.insert(cartridge) -> Cartridge
      #
      # All cartridge versions represented by this manifest into the index
      #
      #   CartridgeRepository.instance.insert(cartridge) -> Cartridge
      def insert(cartridge) # :nodoc:
        vendor            = cartridge.cartridge_vendor
        name              = cartridge.name
        cartridge_version = cartridge.cartridge_version

        Manifest.sort_versions(cartridge.versions).each do |version|
          projected_cartridge = cartridge.project_version_overrides(version, @path)

          @index[vendor][name][version][cartridge_version] = projected_cartridge
          @index[vendor][name][version]['_']               = projected_cartridge
        end

        cartridge
      end

      #
      # Determine whether the latest version present in the index slice is the latest one
      #
      def latest_in_slice?(index_slice, version)
        latest_in_slice(index_slice) == version
      end

      #
      # Determine the latest version present in a slice of the index
      #
      def latest_in_slice(index_slice)
        real_versions = index_slice.keys
        real_versions.delete_if { |v| v == '_' }

        Manifest.sort_versions(real_versions).last
      end

      #
      # Determine the latest cartridge version present for a cart
      #
      def latest_cartridge_version(vendor, cart_name)
        versions = []
        @index[vendor][cart_name].each_value do |cart_version_to_cart|
          versions += cart_version_to_cart.keys.delete_if { |v| v == '_' }
          versions.uniq!
        end

        Manifest.sort_versions(versions).last
      end

      #
      # Determine whether the given cartridge version is the latest for (name, version)
      #
      def latest_cartridge_version?(vendor, name, version, cartridge_version)
        if !exist?(vendor, name, version, cartridge_version)
          return false
        end

        latest_in_slice?(@index[vendor][name][version], cartridge_version)
      end

      # :call-seq:
      #   CartridgeRepository.instance.each -> Cartridge
      #
      # Process each unique cartridge
      #
      #   CartridgeRepository.instance.each {|c| puts c.name}
      def each
        return to_enum(:each) unless block_given?

        cartridges = Set.new
        @index.each_pair do |_, names|
          names.each_pair do |_, sw_hash|
            sw_hash.each_pair do |_, cart_hash|
              cart_hash.each_pair do |_, cartridge|
                cartridges.add(cartridge)
              end
            end
          end
        end

        cartridges.each { |c| yield c }
        self
      end

      # :call-seq:
      #   CartridgeRepository.instance.each_latest -> Cartridge
      #
      # Process each latest version of each software version of each cartridge
      #
      #   CartridgeRepository.instance.each_latest {|c| puts c.name}
      def latest_versions
        cartridges = []

        @index.each do |vendor, names|
          names.each do |name, software_versions|
            lcv = latest_cartridge_version(vendor, name)
            software_versions.keys.sort.reverse.each do |software_version|
              if software_versions[software_version].has_key? lcv
                unless software_versions[software_version][lcv].instance_of?(Hash)
                  latest = software_versions[software_version]['_']
                  cartridges << latest unless latest.instance_of?(Hash)
                end
              end
            end
          end
        end

        if block_given?
          cartridges.each { |c| yield c }
        end

        cartridges
      end

      ## print out all index entries in a table
      def inspect
        @index.inject("<CartridgeRepository:\n") do |memo, (vendor, names)|
          names.inject(memo) do |memo, (name, sw_hash)|
            sw_hash.inject(memo) do |memo, (sw_ver, cart_hash)|
              cart_hash.inject(memo) do |memo, (cart_ver, cartridge)|
                cart_ver != "_" ? memo << "(#{vendor}, #{name}, #{sw_ver}, #{cart_ver}): " << cartridge.to_s << "\n" : memo
              end
            end << '>'
          end
        end
      end

      ## print out all indexed cartridges in a table
      def to_s
        each_with_object('') do |c, memo|
          memo << "(#{c.cartridge_vendor}, #{c.name}, #{c.version}, #{c.cartridge_version})\n"
        end
      end

      # :call-seq:
      #   CartridgeRepository.overlay_cartridge(cartridge, path) -> nil
      #
      # Overlay new code over existing cartridge in a gear;
      #   If the cartridge manifest_path is :url then source_url is used to obtain cartridge source
      #   Otherwise the cartridge source is copied from the cartridge_repository
      #
      #   source_hash is used to ensure the download was successful.
      #
      #   CartridgeRepository.overlay_cartridge(perl_cartridge, '/var/lib/.../mock') => nil
      def self.overlay_cartridge(cartridge, target)
        instantiate_cartridge(cartridge, target, false)
      end

      # :call-seq:
      #   CartridgeRepository.instantiate_cartridge(cartridge, path) -> nil
      #
      # Instantiate a cartridge in a gear;
      #   If the cartridge manifest_path is :url then source_url is used to obtain cartridge source
      #   Otherwise the cartridge source is copied from the cartridge_repository
      #
      #   source_hash is used to ensure the download was successful.
      #
      #   CartridgeRepository.instantiate_cartridge(perl_cartridge, '/var/lib/.../mock') => nil
      def self.instantiate_cartridge(cartridge, target, failure_remove = true)
        FileUtils.mkpath target
        if :url == cartridge.manifest_path
          downloadable = true
        end

        if downloadable
          uri         = URI(cartridge.source_url)
          safe_source = Shellwords.escape(cartridge.source_url)

          temporary = PathUtils.join(File.dirname(target), File.basename(safe_source))
          cartridge.validate_vendor_name
          cartridge.check_reserved_vendor_name
          cartridge.validate_cartridge_name

          case
            when 'git' == uri.scheme || cartridge.source_url.end_with?('.git')
              Utils::oo_spawn(%Q(set -xe;
                               git clone #{safe_source} #{cartridge.name};
                               GIT_DIR=./#{cartridge.name}/.git git repack),
                              chdir:               Pathname.new(target).parent.to_path,
                              expected_exitstatus: 0)

            when uri.scheme =~ /^https*/ && cartridge.source_url =~ /\.zip/
              begin
                uri_copy(URI(cartridge.source_url), temporary, cartridge.source_md5)
                extract(:zip, temporary, target)
              ensure
                FileUtils.rm(temporary)
              end

            when uri.scheme =~ /^https*/ && cartridge.source_url =~ /(\.tar\.gz|\.tgz)$/
              begin
                uri_copy(URI(cartridge.source_url), temporary, cartridge.source_md5)
                extract(:tgz, temporary, target)
              ensure
                FileUtils.rm(temporary)
              end

            when uri.scheme =~ /^https*/ && cartridge.source_url =~ /\.tar$/
              begin
                uri_copy(URI(cartridge.source_url), temporary, cartridge.source_md5)
                extract(:tar, temporary, target)
              ensure
                FileUtils.rm(temporary)
              end

            when 'file' == uri.scheme
              entries = Dir.glob(PathUtils.join(uri.path, '*'), File::FNM_DOTMATCH)
              filesystem_copy(entries, target, %w(. ..))

            else
              raise ArgumentError.new("CLIENT_ERROR: Unsupported URL(#{cartridge.source_url}) for downloading a private cartridge")
          end
        else
          entries = Dir.glob(PathUtils.join(cartridge.repository_path, '*'), File::FNM_DOTMATCH)
          filesystem_copy(entries, target, %w(. .. usr))

          source_usr = PathUtils.join(cartridge.repository_path, 'usr')
          target_usr = PathUtils.join(target, 'usr')

          FileUtils.rm(target_usr) if File.symlink?(target_usr)
          FileUtils.symlink(source_usr, target_usr) if File.exist?(source_usr) && !File.exist?(target_usr)
        end

        if downloadable
          metadata_on_disk = PathUtils.join(target, 'metadata')
          manifest_on_disk = PathUtils.join(metadata_on_disk, 'manifest.yml')
          FileUtils.mkpath(metadata_on_disk) unless File.exist? metadata_on_disk
          IO.write(manifest_on_disk, YAML.dump(cartridge.manifest))
        end

        valid_cartridge_home(cartridge, target)

      rescue => e
        FileUtils.rm_rf target if failure_remove
        raise e
      end

      private

      def self.uri_copy(uri, temporary, md5 = nil)
        content_length = nil
        File.open(temporary, 'w') do |output|
          uri.open(ssl_verify_mode:     OpenSSL::SSL::VERIFY_NONE,
                   content_length_proc: lambda { |l| content_length = l }
          ) do |input|
            input.meta
            begin
              total = 0
              while true
                partial = input.readpartial(4096)
                total   += output.write partial

                if content_length && content_length < total
                  raise Net::HTTPBadResponse.new("CLIENT_ERROR: Download of '#{uri}' exceeded Content-Length of #{content_length}. Download aborted.")
                end
              end
            rescue EOFError
              # we are done
            end
          end
        end

        if content_length && content_length != File.size(temporary)
          raise Net::HTTPBadResponse.new(
                    "CLIENT_ERROR: Download of '#{uri}' failed, expected Content-Length of #{content_length} received #{File.size(temporary)}")
        end

        if md5
          digest = Digest::MD5.file(temporary).hexdigest
          if digest != md5
            raise IOError.new("CLIENT_ERROR: Failed to download cartridge, checksum failed: #{md5} expected, #{digest} actual")
          end
        end
      end

      def self.filesystem_copy(entries, target, black_list)
        entries.delete_if do |e|
          black_list.include? File.basename(e)
        end

        raise ArgumentError.new('CLIENT_ERROR: No cartridge sources found to install.') if entries.empty?

        source = entries.map { |e| Shellwords.escape(e) }
        Utils.oo_spawn("/bin/cp -ad #{source.join(' ')} #{target}",
                       expected_exitstatus: 0)
      end

      def self.extract(method, source, target)
        src = Shellwords.escape(source)
        case method
          when :zip
            Utils.oo_spawn("/usr/bin/unzip -d #{target} #{src}", expected_exitstatus: 0)
          when :tgz
            Utils.oo_spawn("/bin/tar -C #{target} -zxpf #{src}", expected_exitstatus: 0)
          when :tar
            Utils.oo_spawn("/bin/tar -C #{target} -xpf #{src}", expected_exitstatus: 0)
          else
            raise "Packaging method #{method} not yet supported."
        end

        files = Dir.glob(PathUtils.join(target, '*'))
        if 1 == files.size
          # A directory of one file is not legal move everyone up a level (github zip's are this way)
          to_delete = files.first + '.to_delete'
          File.rename(files.first, to_delete)

          entries = Dir.glob(PathUtils.join(to_delete, '*'), File::FNM_DOTMATCH).delete_if do |e|
            %w(. ..).include? File.basename(e)
          end

          FileUtils.move(entries, target)
          FileUtils.rm_rf(to_delete)
        end
      end

      def self.valid_cartridge_home(cartridge, path)
        errors = []
        [
            [File, :directory?, %w(metadata)],
            [File, :directory?, %w(bin)],
            [File, :file?, %w(metadata manifest.yml)]
        ].each do |clazz, method, target|
          relative = PathUtils.join(target)
          absolute = PathUtils.join(path, relative)

          unless clazz.method(method).(absolute)
            errors << "#{relative} is not #{method}"
          end
        end

        unless errors.empty?
          raise MalformedCartridgeError.new(
                    "CLIENT_ERROR: Malformed cartridge (#{cartridge.name}, #{cartridge.version}, #{cartridge.cartridge_version})",
                    errors
                )
        end
      end
    end

    # MalformedCartridgeError will be raised if the cartridge instance is missing
    #   files or they do not have expected settings.
    #
    #  MalformedCartridgeError#message provides minimal information.
    #  MalformedCartridgeError#details or #to_s will provide exact issues.
    #
    class MalformedCartridgeError < RuntimeError
      attr_reader :details

      def initialize(message = nil, details = [])
        super(message)
        @details = details
      end

      def to_s
        super + ":\n#{@details.join(', ')}"
      end
    end
  end
end
