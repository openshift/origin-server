#--
# Copyright 2010 Red Hat, Inc.
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
require 'openshift-origin-node/model/frontend/http/plugins/frontend_http_base'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-node/model/application_container'
require 'openshift-origin-common'
require 'fileutils'
require 'openssl'
require 'fcntl'
require 'json'
require 'tmpdir'
require 'net/http'

module OpenShift
  module Runtime

    class FrontendHttpServerException < StandardError
      attr_reader :container_uuid, :fqdn

      def initialize(msg=nil, container_uuid=nil, fqdn=nil)
        @container_uuid = container_uuid
        @fqdn = fqdn
        super(msg)
      end

      def to_s
        m = super
        m+= ": #{@fqdn}" if not @fqdn.nil?
        m
      end
    end

    class FrontendHttpServerExecException < FrontendHttpServerException
      attr_reader :rc, :stdout, :stderr

      def initialize(msg=nil, container_uuid=nil, fqdn=nil, rc=-1, stdout=nil, stderr=nil)
        @rc=rc
        @stdout=stdout
        @stderr=stderr
        super(msg, container_uuid, fqdn)
      end

      def to_s
        m = super
        m+= ": rc=#{@rc}"         if rc != -1
        m+= ": stdout=#{@stdout}" if not @stdout.nil?
        m+= ": stderr=#{@stderr}" if not @stderr.nil?
      end
    end


    class FrontendHttpServerNameException < FrontendHttpServerException
      attr_reader :server_name

      def initialize(msg=nil, container_uuid=nil, fqdn=nil, server_name=nil)
        @server_name = server_name
        super(msg, container_uuid, fqdn)
      end

      def to_s
        m = super
        m+= ": #{@server_name}" if not @server_name.nil?
        m
      end
    end

    class FrontendHttpServerAliasException < FrontendHttpServerException
      attr_reader :alias_name

      def initialize(msg=nil, container_uuid=nil, fqdn=nil, alias_name=nil)
        @alias_name = alias_name
        super(msg, container_uuid, fqdn)
      end

      def to_s
        m = super
        m+= ": #{@alias_name}" if not @alias_name.nil?
        m
      end
    end


    # == Frontend Http Server
    #
    # Represents the front-end HTTP server on the system.
    #
    #
    class FrontendHttpServer < Model
      include NodeLogger

      # Load the plugins at require time
      ::OpenShift::Config.new.get('OPENSHIFT_FRONTEND_HTTP_PLUGINS',"").split(',').each do |plugin_gem|
        begin
          require plugin_gem
        rescue LoadError => e
          raise ArgumentError.new("error loading #{plugin_gem}: #{e.message}")
        end
      end

      def self.plugins
        ::OpenShift::Runtime::Frontend::Http::Plugins::plugins
      end

      attr_reader :container_uuid
      attr_reader :fqdn
      attr_reader :plugins

      # Public: return an Enumerator which yields FrontendHttpServer
      # objects for each gear which has run create.
      def self.all
        Enumerator.new do |yielder|
          ApplicationContainer.all.each do |container|
            begin
              yielder.yield(self.new(container))
            rescue => e
              NodeLogger.logger.error("Failed to instantiate FrontendHttpServer for #{container.uuid}: #{e}")
              NodeLogger.logger.error("Backtrace: #{e.backtrace}")
            end
          end
        end

      end

      # Public: Purge frontend records for broken gears.
      #
      # Args:
      #   lookup   - either the uuid or fqdn of the broken gear.
      #
      # Note: This API function is intended for use when the
      # ApplicationContainer object is no longer able to instantiate
      # for a gear or no longer has complete information.
      def self.purge(lookup)
        uuid = fqdn = lookup
        plugins.each do |pl|
          [:lookup_by_uuid, :lookup_by_fqdn].each do |call|
            if pl.methods.include?(call)
              entry = pl.send(call, lookup)
              if entry
                uuid = entry.container_uuid if entry.container_uuid
                fqdn = entry.fqdn           if entry.fqdn
              end
            end
          end
        end

        plugins.each do |pl|
          if fqdn and pl.methods.include?(:purge_by_fqdn)
            pl.send(:purge_by_fqdn, fqdn)
          end

          if uuid and pl.methods.include?(:purge_by_uuid)
            pl.send(:purge_by_uuid, uuid)
          end
        end
      end

      def initialize(container)
        @config = ::OpenShift::Config.new

        @container_uuid = container.uuid
        @container_name = container.name
        @namespace = container.namespace

        @standalone_web_proxy = (container.cartridge_model.standalone_web_proxy? rescue false)

        # this is ONLY used when invoking "connect" so the app uuid can be stored
        # in the nodes db, so it can be added to the node openshift_log (access log)
        @application_uuid = container.application_uuid

        if (container.name.to_s == "") or (container.namespace.to_s == "")
          self.class.plugins.each do |pl|
            begin
              entry = pl.lookup_by_uuid(@container_uuid)
              @fqdn = entry.fqdn
              @container_name = entry.container_name
              @namespace = entry.namespace
              break if not @fqdn.nil?
            rescue NoMethodError => e
              # NodeLogger.logger.debug("container #{container.uuid}, NoMethodError #{e.message}")
            end
          end
        else
          cloud_domain = clean_server_name(@config.get("CLOUD_DOMAIN"))
          @fqdn = clean_server_name("#{container.name}-#{container.namespace}.#{cloud_domain}")
        end

        # Could not infer from any source
        if (@fqdn.to_s == "") or (@container_name.to_s == "") or (@namespace.to_s == "")
          raise FrontendHttpServerException.new(%Q{Could not determine gear information for: uuid "#{@container_uuid}" fqdn "#{@fqdn}" container name "#{@container_name}" namespace "#{@namespace}"},
                                                @container_uuid)
        end

        @plugins = self.class.plugins.map { |pl| pl.new(@container_uuid, @fqdn, @container_name, @namespace, @application_uuid) }
      end

      # Public: Change the fqdn for the plugins
      #
      # Useful when multiple fqdns are used for a given gear
      # Returns nil On Success or raises on Failure
      def set_fqdn(new_fqdn)
        @fqdn = new_fqdn
        @plugins.each { |pl| pl.fqdn = new_fqdn }
      end

      # Public: Initialize a new configuration for this gear
      #
      # Examples
      #
      #    create
      #    # => nil
      #
      # Returns nil on Success or raises on Failure
      def create
        call_plugins(:create)
      end

      # Public: Remove the frontend httpd configuration for a gear.
      #
      # Examples
      #
      #    destroy
      #    # => nil
      #
      # Returns nil on Success or raises on Failure
      def destroy
        call_plugins(:destroy)
      end

      # Public: extract hash version of complete data for this gear
      def to_hash
        {
          "container_uuid" => @container_uuid,
          "fqdn"           => @fqdn,
          "container_name" => @container_name,
          "namespace"      => @namespace,
          "connections"    => connections,
          "aliases"        => aliases,
          "ssl_certs"      => ssl_certs,
          "idle"           => idle?,
          "sts"            => get_sts
        }
      end

      # Public: Generate json
      def to_json(*args)
        {
          'json_class' => self.class.name,
          'data'       => self.to_hash
        }.to_json(*args)
      end

      # Public: Load from json
      def self.json_create(obj)
        data = obj['data']

        # Note, the container name, namespace and FQDN can change in this step.
        new_obj = FrontendHttpServer.new(ApplicationContainer.from_uuid(data['container_uuid']))
        new_obj.create

        if data.has_key?("connections")
          new_obj.connect(data["connections"])
        end

        if data.has_key?("aliases")
          new_obj.add_aliases(data["aliases"])
        end

        if data.has_key?("ssl_certs")
          data["ssl_certs"].each do |c, k, a|
            new_obj.add_ssl_cert(c, k, a)
          end
        end

        if data.has_key?("idle")
          if data["idle"]
            new_obj.idle
          else
            new_obj.unidle
          end
        end

        if data.has_key?("sts")
          if data["sts"]
            new_obj.sts(data["sts"])
          else
            new_obj.no_sts
          end
        end

        new_obj
      end


      # Public: Connect path elements to a back-end URI for this namespace.
      #
      # Examples
      #
      #     connect('', '127.0.250.1:8080')
      #     connect('/', '127.0.250.1:8080/')
      #     connect('/phpmyadmin', '127.0.250.2:8080/')
      #     connect('/socket, '127.0.250.3:8080/', {"websocket"=>1}
      #
      #         Options:
      #             websocket      Enable web sockets on a particular path
      #             gone           Mark the path as gone (uri is ignored)
      #             forbidden      Mark the path as forbidden (uri is ignored)
      #             noproxy        Mark the path as not proxied (uri is ignored)
      #             redirect       Use redirection to uri instead of proxy (uri must be a path)
      #             file           Ignore request and load file path contained in uri (must be path)
      #             tohttps        Redirect request to https and use the path contained in the uri (must be path)
      #             target_update  Preserve existing options and update the target.
      #         While more than one option is allowed, the above options conflict with each other.
      #         Additional options may be provided which are target specific.
      #     # => nil
      #
      # Returns nil on Success or raises on Failure
      def connect(*elements)
        elems = elements.flatten.enum_for(:each_slice, 3).map { |path, uri, options| [path, uri, options] }

        paths_to_update = {}
        elems.each do |path, uri, options|
          if options["target_update"] && !@standalone_web_proxy
            paths_to_update[path]=uri
          end
        end

        if not paths_to_update.empty?
          connections.each do |path, uri, options|
            if paths_to_update.include?(path)
              elems.delete_if { |a, b, c| a == path }
              elems << [ path, paths_to_update[path], options ]
              paths_to_update.delete(path)
            end
          end
        end

        paths_to_update.each do |path, uri|
          raise FrontendHttpServerException.new("The target_update option specified but no old configuration: #{path}", @container_uuid, @fqdn)
        end

        call_plugins(:connect, *elems)
      end

      # Public: List connections
      # Returns [ [path, uri, options], [path, uri, options], ...]
      def connections
        conset = Hash.new { |h,k| h[k]={} }

        call_plugins(:connections).each do |path, uri, options|
          conset[[path, uri]].merge!(options) do |key, oldval, newval|
            if key == "protocols"
              [ oldval, newval ].flatten.uniq.sort
            else
              newval
            end
          end
        end

        conset.map { |k,v| [ k, v ].flatten }
      end

      # Public: Disconnect a path element from this namespace
      #
      # Examples
      #
      #     disconnect('')
      #     disconnect('/')
      #     disconnect('/phpmyadmin)
      #     disconnect('/a', '/b', '/c')
      #
      #     # => nil
      #
      # Returns nil on Success or raises on Failure
      def disconnect(*paths)
        call_plugins(:disconnect, *paths)
      end

      # Public: Mark a gear as idled
      #
      # Examples
      #
      #     idle()
      #
      #     # => nil()
      #
      # Returns nil on Success or raises on Failure
      def idle
        call_plugins(:idle)
      end

      # Public: Unmark a gear as idled
      #
      # Examples
      #
      #     unidle()
      #
      #     # => nil()
      #
      # Returns nil on Success or raises on Failure
      def unidle
        call_plugins(:unidle)
      end

      # Public: Make an unprivileged call to unidle the gear
      #
      # Examples
      #
      #     unprivileged_unidle()
      #
      #     # => nil()
      #
      # Returns nil.  This is an opportunistic call, failure conditions
      # are ignored but the call may take over a minute to complete.
      def unprivileged_unidle
        call_plugins(:unprivileged_unidle)
      end

      # Public: Determine whether the gear is idle
      #
      # Examples
      #
      #     idle?
      #
      #     # => true or false
      # Returns true if the gear is idled
      def idle?
        call_plugins(:idle?).each do |val|
          return val if val
        end
        nil
      end


      # Public: Mark a gear for STS
      #
      # Examples
      #
      #     sts(duration)
      #
      #     # => nil()
      #
      # Returns nil on Success or raises on Failure
      def sts(max_age=15768000)
        call_plugins(:sts, max_age)
      end

      # Public: Unmark a gear for sts
      #
      # Examples
      #
      #     nosts()
      #
      #     # => nil()
      #
      # Returns nil on Success or raises on Failure
      def no_sts
        call_plugins(:no_sts)
      end

      # Public: Determine whether the gear has sts
      #
      # Examples
      #
      #     sts?
      #
      #     # => true or nil
      # Returns true if the gear is idled
      def get_sts
        call_plugins(:get_sts).each do |val|
          return val if val
        end
        nil
      end


      # Public: List aliases for this gear
      #
      # Examples
      #
      #     aliases
      #     # => ["foo.example.com", "bar.example.com"]
      def aliases
        call_plugins(:aliases)
      end

      # Public: Add an alias to this namespace
      #
      # Examples
      #
      #     add_alias("foo.example.com")
      #     # => nil
      #
      # Returns nil on Success or raises on Failure
      def add_alias(name)
        call_plugins(:add_alias, clean_server_name(name))
      end

      # Public: Add aliases to this namespace
      #
      # Examples
      #
      #     add_aliases([ "foo.example.com", "bar.example.com" ])
      #     # => nil
      #
      # Returns nil on Success or raises on Failure
      def add_aliases(names)
        call_plugins(:add_aliases, names.collect { |name| clean_server_name(name) })
      end

      # Public: Removes an alias from this namespace
      #
      # Examples
      #
      #     add_alias("foo.example.com")
      #     # => nil
      #
      # Returns nil on Success or raises on Failure
      def remove_alias(name)
        call_plugins(:remove_alias, clean_server_name(name))
      end

      # Public: Removes aliases from this namespace
      #
      # Examples
      #
      #     remove_aliases([ "foo.example.com", "bar.example.com" ])
      #     # => nil
      #
      # Returns nil on Success or raises on Failure
      def remove_aliases(names)
        call_plugins(:remove_aliases, names.collect { |name| clean_server_name(name) })
      end

      # Public: List aliases with SSL certs and unencrypted private keys
      def ssl_certs
        call_plugins(:ssl_certs)
      end

      # Public: Adds a ssl certificate for an alias
      def add_ssl_cert(ssl_cert, priv_key, server_alias, passphrase='')
        server_alias_clean = clean_server_name(server_alias)

        begin
          priv_key_clean = OpenSSL::PKey.read(priv_key, passphrase)
          ssl_cert_clean = []
          ssl_cert_unit = ""
          ssl_cert.each_line do |cert_line|
            ssl_cert_unit += cert_line
            if cert_line.start_with?('-----END')
              ssl_cert_clean << OpenSSL::X509::Certificate.new(ssl_cert_unit)
              ssl_cert_unit = ""
            end
          end
        rescue ArgumentError
          raise FrontendHttpServerException.new("Invalid Private Key or Passphrase",
                                                @container_uuid, @fqdn)
        rescue OpenSSL::X509::CertificateError => e
          raise FrontendHttpServerException.new("Invalid X509 Certificate: #{e.message}",
                                                @container_uuid, @fqdn)
        rescue => e
          raise FrontendHttpServerException.new("Other key/cert error: #{e.message}",
                                                @container_uuid, @fqdn)
        end

        if ssl_cert_clean.empty?
          raise FrontendHttpServerException.new("Could not parse certificates",
                                                @container_uuid, @fqdn)
        end

        if not ssl_cert_clean[0].check_private_key(priv_key_clean)
          raise FrontendHttpServerException.new("Key/cert mismatch",
                                                @container_uuid, @fqdn)
        end

        if not [OpenSSL::PKey::RSA, OpenSSL::PKey::DSA].include?(priv_key_clean.class)
          raise FrontendHttpServerException.new("Key must be RSA or DSA for Apache mod_ssl",
                                                @container_uuid, @fqdn)
        end

        call_plugins(:add_ssl_cert,
                     ssl_cert_clean.map { |c| c.to_pem}.join,
                     priv_key_clean.to_pem,
                     server_alias_clean)
      end

      # Public: Removes ssl certificate/private key associated with an alias
      def remove_ssl_cert(server_alias)
        call_plugins(:remove_ssl_cert, clean_server_name(server_alias))
      end


      # Private: Call the plugin list and collect an array of the
      # results.
      #
      #
      def call_plugins(call, *args)
        @plugins.map { |pl|
          begin
            # Support for any method is optional in any plugin
            if pl.methods.include?(call)
              pl.send(call, *args)
            end
          # The public facing exceptions should all be FrontendHttp*Exception.
          rescue ::OpenShift::Runtime::Frontend::Http::Plugins::PluginException => e
            raise FrontendHttpServerException.new(e.message.gsub(": #{@container_uuid}",'').gsub(": #{@fqdn}",''), @container_uuid, @fqdn)
          rescue ::OpenShift::Runtime::Frontend::Http::Plugins::PluginExecException => e
            raise FrontendHttpServerExecException.new(e.message.gsub(": #{@container_uuid}",'').gsub(": #{@fqdn}",''), @container_uuid, @fqdn, e.rc, e.stdout, e.stderr)
          end
        }.flatten(1).select { |res| not res.nil? }.uniq
      end

      # Private: Validate the server name
      #
      # The name is validated against DNS host name requirements from
      # RFC 1123 and RFC 952.  Additionally, OpenShift does not allow
      # names/aliases to be an IP address.
      def clean_server_name(name)
        dname = name.downcase.chomp('.')

        if not dname =~ /^[a-z0-9]/
          raise FrontendHttpServerNameException.new("Invalid start character", @container_uuid, @fqdn, dname )
        end

        if not dname =~ /[a-z0-9]$/
          raise FrontendHttpServerNameException.new("Invalid end character", @container_uuid, @fqdn, dname )
        end

        if not dname.index(/[^0-9a-z\-.]/).nil?
          raise FrontendHttpServerNameException.new("Invalid characters", @container_uuid, @fqdn, dname )
        end

        if dname.length > 255
          raise FrontendHttpServerNameException.new("Too long", @container_uuid, @fqdn, dname )
        end

        if dname.length == 0
          raise FrontendHttpServerNameException.new("Name was blank", @container_uuid, @fqdn, dname )
        end

        if dname =~ /^\d+\.\d+\.\d+\.\d+$/
          raise FrontendHttpServerNameException.new("IP addresses are not allowed", @container_uuid, @fqdn, dname )
        end

        return dname
      end

    end

  end
end
