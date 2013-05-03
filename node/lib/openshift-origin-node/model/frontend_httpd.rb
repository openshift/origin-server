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
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-common'
require 'fileutils'
require 'openssl'
require 'fcntl'
require 'json'
require 'tmpdir'
require 'net/http'

module OpenShift
  
  class FrontendHttpServerException < StandardError
    attr_reader :container_uuid, :container_name
    attr_reader :namespace

    def initialize(msg=nil, container_uuid=nil, container_name=nil, namespace=nil)
      @container_uuid = container_uuid
      @container_name = container_name
      @namespace = namespace
      super(msg)
    end

    def to_s
      m = super
      m+= ": #{@container_name}" if not @container_name.nil?
      m+= ": #{@namespace}" if not @namespace.nil?
      m
    end

  end

  class FrontendHttpServerExecException < FrontendHttpServerException
    attr_reader :rc, :stdout, :stderr

    def initialize(msg=nil, container_uuid=nil, container_name=nil, namespace=nil, rc=-1, stdout=nil, stderr=nil)
      @rc=rc
      @stdout=stdout
      @stderr=stderr
      super(msg, container_uuid, container_name, namespace)
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

    def initialize(msg=nil, container_uuid=nil, container_name=nil, namespace=nil, server_name=nil)
      @server_name = server_name
      super(msg, container_uuid, container_name, namespace)
    end

    def to_s
      m = super
      m+= ": #{@server_name}" if not @server_name.nil?
      m
    end

  end

  class FrontendHttpServerAliasException < FrontendHttpServerException
    attr_reader :alias_name

    def initialize(msg=nil, container_uuid=nil, container_name=nil, namespace=nil, alias_name=nil)
      @alias_name = alias_name
      super(msg, container_uuid, container_name, namespace)
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
  # Note: This is the Apache VirtualHost implementation; other implementations may vary.
  #
  class FrontendHttpServer < Model
    include NodeLogger

    attr_reader :container_uuid, :container_name
    attr_reader :namespace, :fqdn

    # Public: return an Enumerator which yields FrontendHttpServer
    # objects for each gear which has run create.
    def self.all
      Enumerator.new do |yielder|

        # Avoid deadlocks by listing the gears first
        gearlist = {}
        GearDB.open(GearDB::READER) do |d|
          d.each do |uuid, container|
            gearlist[uuid.clone] = container.clone
          end
        end

        gearlist.each do |uuid, container|
          frontend = nil
          begin
            frontend = FrontendHttpServer.new(uuid, container['container_name'], container['namespace'])
          rescue => e
            NodeLogger.logger.error("Failed to instantiate FrontendHttpServer for #{uuid}: #{e}")
            NodeLogger.logger.error("Backtrace: #{e.backtrace}")
          else
            yielder.yield(frontend)
          end
        end
      end

    end

    def initialize(container_uuid, container_name=nil, namespace=nil)
      @config = OpenShift::Config.new

      @cloud_domain = clean_server_name(@config.get("CLOUD_DOMAIN"))

      @basedir = @config.get("OPENSHIFT_HTTP_CONF_DIR")

      @container_uuid = container_uuid
      @container_name = container_name
      @namespace = namespace

      @fqdn = nil

      # Did we save the old information?
      if (@container_name.to_s == "") or (@namespace.to_s == "")
        begin
          GearDB.open(GearDB::READER) do |d|
            @container_name = d.fetch(@container_uuid).fetch('container_name')
            @namespace = d.fetch(@container_uuid).fetch('namespace')
            @fqdn = d.fetch(@container_uuid).fetch('fqdn')
          end
        rescue
        end
      end

      # Last ditch, attempt to infer from the gear itself
      if (@container_name.to_s == "") or (@namespace.to_s == "")
        begin
          env = Utils::Environ.for_gear(File.join(@config.get("GEAR_BASE_DIR"), @container_uuid))
          @fqdn = clean_server_name(env['OPENSHIFT_GEAR_DNS'])
          @container_name = env['OPENSHIFT_GEAR_NAME']
          @namespace = env['OPENSHIFT_GEAR_DNS'].sub(/\..*$/,"").sub(/^.*\-/,"")
        rescue
        end
      end

      # Could not infer from any source
      if (@container_name.to_s == "") or (@namespace.to_s == "")
        raise FrontendHttpServerException.new("Name or namespace not specified and could not infer it",
                                              @container_uuid)
      end

      if @fqdn.nil?
        @fqdn = clean_server_name("#{@container_name}-#{@namespace}.#{@cloud_domain}")
      end

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
      GearDB.open(GearDB::WRCREAT) do |d|
        d.store(@container_uuid, {'fqdn' => @fqdn,  'container_name' => @container_name, 'namespace' => @namespace})
      end
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
      ApacheDBNodes.open(ApacheDBNodes::WRCREAT)     { |d| d.delete_if { |k, v| k.split('/')[0] == @fqdn } }
      ApacheDBAliases.open(ApacheDBAliases::WRCREAT) { |d| d.delete_if { |k, v| v == @fqdn } }
      ApacheDBIdler.open(ApacheDBIdler::WRCREAT)     { |d| d.delete(@fqdn) }
      ApacheDBSTS.open(ApacheDBSTS::WRCREAT)         { |d| d.delete(@fqdn) }
      NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT)   { |d| d.delete_if { |k, v| (k == @fqdn) or (v["alias"] == @fqdn) } }
      GearDB.open(GearDB::WRCREAT)                   { |d| d.delete(@container_uuid) }

      # Clean up SSL certs and legacy node configuration
      ApacheDBAliases.open(ApacheDBAliases::WRCREAT) do
        paths = Dir.glob(File.join(@basedir, "#{container_uuid}_*"))
        FileUtils.rm_rf(paths)
        paths.each do |p|
          if p =~ /\.conf$/
            begin
              reload_httpd
            rescue
            end
            break
          end
        end
      end

    end

    # Public: extract hash version of complete data for this gear
    def to_hash
      {
        "container_uuid" => @container_uuid,
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
      new_obj = new(data['container_uuid'],
                    data['container_name'],
                    data['namespace'])
      new_obj.create

      if data.has_key?("connections")
        new_obj.connect(data["connections"])
      end

      if data.has_key?("aliases")
        data["aliases"].each do |a|
          new_obj.add_alias(a)
        end
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


    # Public: Update identifier to the new names
    def update(container_name, namespace)
      if (container_name == @container_name) and (namespace == @namespace)
        return nil
      end

      saved_ssl_certs = ssl_certs

      new_fqdn = clean_server_name("#{container_name}-#{namespace}.#{@cloud_domain}")

      ApacheDBNodes.open(ApacheDBNodes::WRCREAT) do |d|
        d.update_block do |deletions, updates, k, v|
          if k.split('/')[0] == @fqdn
            deletions << k
            updates[k.sub(@fqdn, new_fqdn)] = v
          end
        end
      end

      ApacheDBAliases.open(ApacheDBAliases::WRCREAT) do |d|
        d.update_block do |deletions, updates, k, v|
          if v == @fqdn
            updates[k]=new_fqdn
          end
        end
      end

      ApacheDBIdler.open(ApacheDBIdler::WRCREAT) do |d|
        d.update_block do |deletions, updates, k, v|
          if k == @fqdn
            deletions << k
            updates[new_fqdn] = v
          end
        end
      end

      ApacheDBSTS.open(ApacheDBSTS::WRCREAT) do |d|
        d.update_block do |deletions, updates, k, v|
          if k == @fqdn
            deletions << k
            updates[new_fqdn] = v
          end
        end
      end

      NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
        d.update_block do |deletions, updates, k, v|
          if k == @fqdn
            deletions << k
            updates[new_fqdn] = v
          end
        end
      end

      GearDB.open(GearDB::WRCREAT) do |d|
        d.store(@container_uuid, {'fqdn' => new_fqdn,  'container_name' => container_name, 'namespace' => namespace})
      end

      old_namespace = @namespace

      @container_name = container_name
      @namespace = namespace
      @fqdn = new_fqdn

      saved_ssl_certs.each do |c, k, a|
        add_ssl_cert(c, k, a)
        old_path = File.join(@basedir, "#{@container_uuid}_#{old_namespace}_#{a}")
        FileUtils.rm_rf(old_path + ".conf")
        FileUtils.rm_rf(old_path)
        reload_httpd
      end
    end

    def update_name(container_name)
      update(container_name, @namespace)
    end

    def update_namespace(namespace)
      update(@container_name, namespace)
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
    #         While more than one option is allowed, the above options conflict with each other.
    #         Additional options may be provided which are target specific.
    #     # => nil
    #
    # Returns nil on Success or raises on Failure
    def connect(*elements)

      ApacheDBNodes.open(ApacheDBNodes::WRCREAT) do |d|

        elements.flatten.enum_for(:each_slice, 3).each do |path, uri, options|

          if options["gone"]
            map_dest = "GONE"
          elsif options["forbidden"]
            map_dest = "FORBIDDEN"
          elsif options["noproxy"]
            map_dest = "NOPROXY"
          elsif options["health"]
            map_dest = "HEALTH"
          elsif options["redirect"]
            map_dest = "REDIRECT:#{uri}"
          elsif options["file"]
            map_dest = "FILE:#{uri}"
          elsif options["tohttps"]
            map_dest = "TOHTTPS:#{uri}"
          else
            map_dest = uri
          end

          if options["websocket"]
            connect_websocket(path, uri, options)
          else
            disconnect_websocket(path) # We could be changing a path
          end

          d.store(@fqdn + path.to_s, map_dest)
        end
      end

    end

    def connect_websocket(path, uri, options)

      if path != ""
        raise FrontendHttpServerException.new("Path must be empty for a websocket: #{path}",
                                              @container_uuid, @container_name, @namespace)

      end

      conn = options["connections"]
      if conn.nil?
        conn = 5
      end

      bw = options["bandwidth"]
      if bw.nil?
        bw = 100
      end

      # Use the websocket port if it is passed as an option
      port = options["websocket_port"]
      if port
        uri = uri.sub(/:(\d)+/, ":" + port.to_s)
      end

      routes_ent = {
        "endpoints" => [ uri ],
        "limits"    => {
          "connections" => conn,
          "bandwidth"   => bw
        }
      }

      NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
        d.store(@fqdn, routes_ent)
      end

    end

    # Public: List connections
    # Returns [ [path, uri, options], [path, uri, options], ...]
    def connections
      # We can't simply rely on the open returning the block's value in unit testing.
      # http://rubyforge.org/tracker/?func=detail&atid=7477&aid=8687&group_id=1917
      entries = nil
      ApacheDBNodes.open(ApacheDBNodes::READER) do |d|
        entries = d.select { |k, v|
          k.split('/')[0] == @fqdn
        }.map { |k, v|
          entry = [ k.sub(@fqdn, ""), "", {} ]

          if entry[0] == ""
            begin
              NodeJSDBRoutes.open(NodeJSDBRoutes::READER) do |d|
                routes_ent = d.fetch(@fqdn)
                entry[2].merge!(routes_ent["limits"])
                entry[2]["websocket"]=1
              end
            rescue
            end
          end

          if v =~ /^(GONE|FORBIDDEN|NOPROXY|HEALTH)$/
            entry[2][$~[1].downcase] = 1
          elsif v =~ /^(REDIRECT|FILE|TOHTTPS):(.*)$/
            entry[2][$~[1].downcase] = 1
            entry[1] = $~[2]
          else
            entry[1] = v
          end
          entry
        }
      end
      entries
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
      ApacheDBNodes.open(ApacheDBNodes::WRCREAT) do |d|
        paths.each do |p|
          d.delete(@fqdn + p.to_s)
        end
      end
      disconnect_websocket(*paths)
    end

    def disconnect_websocket(*paths)
      if paths.include?("")
        NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
          d.delete(@fqdn)
        end
      end
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
      ApacheDBIdler.open(ApacheDBIdler::WRCREAT) do |d|
        d.store(@fqdn, @container_uuid)
      end
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
      ApacheDBIdler.open(ApacheDBIdler::WRCREAT) do |d|
        d.delete(@fqdn)
      end
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
      begin
        http = Net::HTTP.new('127.0.0.1', 80)
        http.open_timeout = 5
        http.read_timeout = 60
        http.use_ssl = false
        http.start do |client|
          resp = client.request_head('/', { 'Host' => @fqdn })
          resp.code
        end
      rescue
      end
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
      ApacheDBIdler.open(ApacheDBIdler::READER) do |d|
        return d.has_key?(@fqdn)
      end
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
      ApacheDBSTS.open(ApacheDBSTS::WRCREAT) do |d|
        if max_age.nil?
          d.delete(@fqdn)
        else
          d.store(@fqdn, max_age.to_i)
        end
      end
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
      ApacheDBSTS.open(ApacheDBSTS::WRCREAT) do |d|
        d.delete(@fqdn)
      end
    end

    # Public: Determine whether the gear has sts
    #
    # Examples
    #
    #     sts?
    #
    #     # => true or false
    # Returns true if the gear is idled
    def get_sts
      ApacheDBSTS.open(ApacheDBSTS::READER) do |d|
        if d.has_key?(@fqdn)
          return d.fetch(@fqdn)
        end
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
      ApacheDBAliases.open(ApacheDBAliases::READER) do |d|
        return d.select { |k, v| v == @fqdn }.map { |k, v| k }
      end
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
      dname = clean_server_name(name)

      # Broker checks for global uniqueness
      ApacheDBAliases.open(ApacheDBAliases::WRCREAT) do |d|
        d.store(dname, @fqdn)
      end

      NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
        begin
          routes_ent = d.fetch(@fqdn)
          if not routes_ent.nil?
            alias_ent = routes_ent.clone
            alias_ent["alias"] = @fqdn
            d.store(name, alias_ent)
          end
        rescue KeyError
        end
      end

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
      dname = clean_server_name(name)

      ApacheDBAliases.open(ApacheDBAliases::WRCREAT) do |d|
        d.delete(dname)
      end

      NodeJSDBRoutes.open(NodeJSDBRoutes::WRCREAT) do |d|
        d.delete(dname)
      end

      remove_ssl_cert(dname)
    end

    # Public: List aliases with SSL certs and unencrypted private keys
    def ssl_certs
      aliases.map { |a|
        alias_token = "#{@container_uuid}_#{@namespace}_#{a}"
        alias_conf_dir_path = File.join(@basedir, alias_token)
        ssl_cert_file_path = File.join(alias_conf_dir_path, a + ".crt")
        priv_key_file_path = File.join(alias_conf_dir_path, a + ".key")

        begin
          ssl_cert = File.read(ssl_cert_file_path)
          priv_key = File.read(priv_key_file_path)
        rescue
          ssl_cert = nil
          priv_key = nil
        end

        [ ssl_cert, priv_key, a ]
      }.select { |e| e[0] != nil }
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
                                              @container_uuid, @container_name,
                                              @namespace)
      rescue OpenSSL::X509::CertificateError => e
        raise FrontendHttpServerException.new("Invalid X509 Certificate: #{e.message}",
                                              @container_uuid, @container_name,
                                              @namespace)
      rescue => e
        raise FrontendHttpServerException.new("Other key/cert error: #{e.message}",
                                              @container_uuid, @container_name,
                                              @namespace)
      end

      if ssl_cert_clean.empty?
        raise FrontendHttpServerException.new("Could not parse certificates",
                                              @container_uuid, @container_name,
                                              @namespace)
      end

      if not ssl_cert_clean[0].check_private_key(priv_key_clean)
        raise FrontendHttpServerException.new("Key/cert mismatch",
                                              @container_uuid, @container_name,
                                              @namespace)
      end

      if not [OpenSSL::PKey::RSA, OpenSSL::PKey::DSA].include?(priv_key_clean.class)
        raise FrontendHttpServerException.new("Key must be RSA or DSA for Apache mod_ssl",
                                              @container_uuid, @container_name,
                                              @namespace)
      end


      # Create a new directory for the alias and copy the certificates
      alias_token = "#{@container_uuid}_#{@namespace}_#{server_alias_clean}"
      alias_conf_dir_path = File.join(@basedir, alias_token)
      ssl_cert_file_path = File.join(alias_conf_dir_path, server_alias_clean + ".crt")
      priv_key_file_path = File.join(alias_conf_dir_path, server_alias_clean + ".key")

      #
      # Create configuration for the alias
      #

      # Create top level config file for the alias
      alias_conf_contents = <<-ALIAS_CONF_ENTRY
<VirtualHost *:443>
  ServerName #{server_alias_clean}
  ServerAdmin openshift-bofh@redhat.com
  DocumentRoot /var/www/html
  DefaultType None

  SSLEngine on
  
  SSLCertificateFile #{ssl_cert_file_path}
  SSLCertificateKeyFile #{priv_key_file_path}
  SSLCertificateChainFile #{ssl_cert_file_path}
  SSLCipherSuite RSA:!EXPORT:!DH:!LOW:!NULL:+MEDIUM:+HIGH
  SSLProtocol -ALL +SSLv3 +TLSv1
  SSLOptions +StdEnvVars +ExportCertData
  # SSLVerifyClient must be set for +ExportCertData to take effect, so just use
  # optional_no_ca.
  SSLVerifyClient optional_no_ca

  RequestHeader set X-Forwarded-Proto "https"
  RequestHeader set X-Forwarded-SSL-Client-Cert %{SSL_CLIENT_CERT}e

  RewriteEngine On
  include conf.d/openshift_route.include

</VirtualHost>
      ALIAS_CONF_ENTRY

      # Finally, commit the changes
      ApacheDBAliases.open(ApacheDBAliases::WRCREAT) do |d|
        if not (d.has_key? server_alias_clean)
          raise FrontendHttpServerException.new("Specified alias #{server_alias_clean} does not exist for the app",
                                                @container_uuid, @container_name,
                                                @namespace)
        end

        FileUtils.mkdir_p(alias_conf_dir_path)
        File.open(ssl_cert_file_path, 'w') { |f| f.write(ssl_cert_clean.map { |c| c.to_pem}.join) }
        File.open(priv_key_file_path, 'w') { |f| f.write(priv_key_clean.to_pem) }

        alias_conf_file_path = File.join(@basedir, "#{alias_token}.conf")
        File.open(alias_conf_file_path, 'w') { |f| f.write(alias_conf_contents) }

        # Reload httpd to pick up the new configuration
        reload_httpd
      end
    end

    # Public: Removes ssl certificate/private key associated with an alias
    def remove_ssl_cert(server_alias)
      server_alias_clean = clean_server_name(server_alias)

      #
      # Remove the alias specific configuration
      #
      alias_token = "#{@container_uuid}_#{@namespace}_#{server_alias_clean}"

      alias_conf_dir_path = File.join(@basedir, alias_token)
      alias_conf_file_path = File.join(@basedir, "#{alias_token}.conf")

      if File.exists?(alias_conf_file_path) or File.exists?(alias_conf_dir_path)
        ApacheDBAliases.open(ApacheDBAliases::WRCREAT) do

          FileUtils.rm_rf(alias_conf_file_path)
          FileUtils.rm_rf(alias_conf_dir_path)

          # Reload httpd to pick up the configuration changes
          reload_httpd
        end
      end
    end

    # Private: Validate the server name
    #
    # The name is validated against DNS host name requirements from
    # RFC 1123 and RFC 952.  Additionally, OpenShift does not allow
    # names/aliases to be an IP address.
    def clean_server_name(name)
      dname = name.downcase

      if not dname.index(/[^0-9a-z\-.]/).nil?
        raise FrontendHttpServerNameException.new("Invalid characters", @container_uuid, \
                                                   @container_name, @namespace, dname )
      end

      if dname.length > 255
        raise FrontendHttpServerNameException.new("Too long", @container_uuid, \
                                                  @container_name, @namespace, dname )
      end

      if dname.length == 0
        raise FrontendHttpServerNameException.new("Name was blank", @container_uuid, \
                                                  @container_name, @namespace, dname )
      end

      if dname =~ /^\d+\.\d+\.\d+\.\d+$/
        raise FrontendHttpServerNameException.new("IP addresses are not allowed", @container_uuid, \
                                                  @container_name, @namespace, dname )
      end

      return dname
    end

    # Reload the Apache configuration
    def reload_httpd(async=false)
      async_opt="-b" if async
      begin
        Utils::oo_spawn("/usr/sbin/oo-httpd-singular #{async_opt} graceful", {:expected_exitstatus=>0})
      rescue Utils::ShellExecutionException => e
        logger.error("ERROR: failure from oo-httpd-singular(#{e.rc}): #{@uuid} stdout: #{e.stdout} stderr:#{e.stderr}")
        raise FrontendHttpServerExecException.new(e.message, @container_uuid, @container_name, @namespace, e.rc, e.stdout, e.stderr)
      end
    end

  end


  # Present an API to Apache's DB files for mod_rewrite.
  #
  # The process to update database files is complicated and
  # hand-editing is strongly discouraged for the following reasons:
  #
  # 1. There did not appear to be a corruption free database format in
  # common between ruby and Apache that had a guaranteed consistent
  # API.  Even BerkeleyDB and the BDB module corrupted each other on
  # testing.
  #
  # 2. Every effort was made to ensure that a crash, even due to a
  # system issue such as disk space or memory starvation did not
  # result in a corrupt database and the loss of old information.
  #
  # 3. Every effort was made to ensure that multiple threads and
  # processes could not corrupt or step on each other.
  #
  # 4. While the httxt2dbm tool can run on an existing database, that
  # will result in additions but not removals from the database.  Only
  # some of your changes will take unless the entire db is recreated
  # each time.
  #
  # 5. In order for BerkeleyDB to be safe for multiple processes to
  # access/edit, the environment must be specifically set up to allow
  # locking.  An audit of the Apache source code shows that it does
  # not do that.  And an strace of Apache shows no attempt to either
  # lock or establish a mutex on the BerkeleyDB file.  I believe the
  # claim that BerkeleyDB is safe to have multiple processess
  # reading/writing it is simply not true the way its used by Apache.
  #
  #
  # This locks down to one thread for safety.  You MUST ensure that
  # close is called to release all locks.  Close also syncs changes to
  # Apache if data was modified.
  #
  class ApacheDB < Hash
    include NodeLogger

    # The locks and lockfiles are based on the file name
    @@LOCKS = Hash.new { |h, k| h[k] = Mutex.new }
    @@LOCKFILEBASE = "/var/run/openshift/ApacheDB"

    READER  = Fcntl::O_RDONLY
    WRITER  = Fcntl::O_RDWR
    WRCREAT = Fcntl::O_RDWR | Fcntl::O_CREAT
    NEWDB   = Fcntl::O_RDWR | Fcntl::O_CREAT | Fcntl::O_TRUNC

    class_attribute :MAPNAME
    self.MAPNAME = nil

    class_attribute :SUFFIX
    self.SUFFIX = ".txt"

    def initialize(flags=nil)
      @closed = false

      if self.MAPNAME.nil?
        raise NotImplementedError.new("Must subclass with proper map name.")
      end

      @config = OpenShift::Config.new
      @basedir = @config.get("OPENSHIFT_HTTP_CONF_DIR")

      @mode = 0640

      if flags.nil?
        @flags = READER
      else
        @flags = flags
      end

      @filename = File.join(@basedir, self.MAPNAME)

      @lockfile = @@LOCKFILEBASE + '.' + self.MAPNAME + self.SUFFIX + '.lock'

      super()

      # Each filename needs its own mutex and lockfile
      @@LOCKS[@lockfile].lock

      begin
        @lfd = File.new(@lockfile, Fcntl::O_RDWR | Fcntl::O_CREAT, 0640)

        if writable?
          @lfd.flock(File::LOCK_EX)
        else
          @lfd.flock(File::LOCK_SH)
        end

        if @flags != NEWDB
          reload
        end

      rescue
        begin
          if not @lfd.nil?
            @lfd.close()
          end
        ensure
          @@LOCKS[@lockfile].unlock
        end
        raise
      end

    end

    def decode_contents(f)
      f.each do |l|
        path, dest = l.strip.split
        if (not path.nil?) and (not dest.nil?)
          self.store(path, dest)
        end
      end
    end

    def encode_contents(f)
      self.each do |k, v|
        f.write([k, v].join(' ') + "\n")
      end
    end

    def reload
      begin
        File.open(@filename + self.SUFFIX, Fcntl::O_RDONLY) do |f|
          decode_contents(f)
        end
      rescue Errno::ENOENT
        if not [WRCREAT, NEWDB].include?(@flags)
          raise
        end
      end
    end

    def writable?
      [WRITER, WRCREAT, NEWDB].include?(@flags)
    end

    def callout
      # Use Berkeley DB so that there's no race condition between
      # multiple file moves.  The Berkeley DB implementation creates a
      # scratch working file under certain circumstances.  Use a
      # scratch dir to protect it.
      Dir.mktmpdir([File.basename(@filename) + ".db-", ""], File.dirname(@filename)) do |wd|
        tmpdb = File.join(wd, 'new.db')

        httxt2dbm = ["/usr/bin","/usr/sbin","/bin","/sbin"].map {|d| File.join(d, "httxt2dbm")}.select {|p| File.exists?(p)}.pop
        if httxt2dbm.nil?
          logger.warn("WARNING: no httxt2dbm command found, relying on PATH")
          httxt2dbm="httxt2dbm"
        end

        cmd = %{#{httxt2dbm} -f DB -i #{@filename}#{self.SUFFIX} -o #{tmpdb}}
        out,err,rc = Utils::oo_spawn(cmd)
        if rc == 0
          logger.debug("httxt2dbm: #{@filename}: #{rc}: stdout: #{out} stderr:#{err}")
          begin
            oldstat = File.stat(@filename + '.db')
            File.chown(oldstat.uid, oldstat.gid, tmpdb)
            File.chmod(oldstat.mode & 0777, tmpdb)
          rescue Errno::ENOENT
          end
          FileUtils.mv(tmpdb, @filename + '.db', :force=>true)
        else
          logger.error("ERROR: failure httxt2dbm #{@filename}: #{rc}: stdout: #{out} stderr:#{err}") unless rc == 0
        end
      end
    end

    def flush
      if writable?
        File.open(@filename + self.SUFFIX + '-', Fcntl::O_RDWR | Fcntl::O_CREAT | Fcntl::O_TRUNC, 0640) do |f|
          encode_contents(f)
        end

        # Ruby 1.9 Hash preserves order, compare files to see if anything changed
        if FileUtils.compare_file(@filename + self.SUFFIX + '-', @filename + self.SUFFIX)
          FileUtils.rm(@filename + self.SUFFIX + '-', :force=>true)
        else
          begin
            oldstat = File.stat(@filename + self.SUFFIX)
            FileUtils.chown(oldstat.uid, oldstat.gid, @filename + self.SUFFIX + '-')
            FileUtils.chmod(oldstat.mode & 0777, @filename + self.SUFFIX + '-')
          rescue Errno::ENOENT
          end
          FileUtils.mv(@filename + self.SUFFIX + '-', @filename + self.SUFFIX, :force=>true)
          callout
        end
      end
    end

    def close
      @closed=true
      begin
        begin
          self.flush
        ensure
          @lfd.close() unless @lfd.closed?
        end
      ensure
        @@LOCKS[@lockfile].unlock if @@LOCKS[@lockfile].locked?
      end
    end

    def closed?
      @closed
    end

    # Preferred method of access is to feed a block to open so we can
    # guarantee the close.
    def self.open(flags=nil)
      inst = new(flags)
      if block_given?
        begin
          return yield(inst)
        rescue
          @flags = nil # Disable flush
          raise
        ensure
          if not inst.closed?
            inst.close
          end
        end
      end
      inst
    end

    # Public, update using a block
    # The block is called for each key, value pair of the hash
    # and uses the following parameters:
    #    deletions   Array of keys to delete
    #    updates     Hash of key->value pairs to add/update
    #    k, v        Key and value of this iteration
    def update_block
      deletions = []
      updates = {}
      self.each do |k, v|
        yield(deletions, updates, k, v)
      end
      self.delete_if { |k, v| deletions.include?(k) }
      self.update(updates)
    end

  end

  class ApacheDBNodes < ApacheDB
    self.MAPNAME = "nodes"
  end

  class ApacheDBAliases < ApacheDB
    self.MAPNAME = "aliases"
  end

  class ApacheDBIdler < ApacheDB
    self.MAPNAME = "idler"
  end


  class ApacheDBSTS < ApacheDB
    self.MAPNAME = "sts"
  end


  # Manage the nodejs route file via the same API as Apache
  class ApacheDBJSON < ApacheDB
    self.SUFFIX = ".json"

    def decode_contents(f)
      begin
        self.replace(JSON.load(f))
      rescue TypeError, JSON::ParserError
      end
    end

    def encode_contents(f)
      f.write(JSON.generate(self.to_hash))
    end

    def callout
    end
  end

  class NodeJSDB < ApacheDBJSON
    include NodeLogger

    def callout
      begin
        Utils::oo_spawn("service openshift-node-web-proxy reload",{:expected_exitstatus=>0})
      rescue Utils::ShellExecutionException => e
        logger.error("ERROR: failure from openshift-node-web-proxy(#{e.rc}) stdout: #{e.stdout} stderr:#{e.stderr}")
      end
    end

  end

  class NodeJSDBRoutes < NodeJSDB
    self.MAPNAME = "routes"
  end

  class GearDB < ApacheDBJSON
    self.MAPNAME = "geardb"
  end

  # TODO: Manage SNI Certificate and alias store
  class ApacheSNIDB
  end

end
