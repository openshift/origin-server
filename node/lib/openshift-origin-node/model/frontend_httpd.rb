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
require 'openshift-origin-common'
require 'syslog'
require 'fileutils'
require 'systemu'

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
    include OpenShift::Utils::ShellExec

    attr_reader :container_uuid, :container_name
    attr_reader :namespace

    def initialize(container_uuid, container_name, namespace)
      Syslog.open('openshift-origin-node', Syslog::LOG_PID, Syslog::LOG_LOCAL0) unless Syslog.opened?

      @config = OpenShift::Config.new
      @container_uuid = container_uuid
      @container_name = container_name
      @namespace = namespace
      @cloud_domain = @config.get("CLOUD_DOMAIN")
    end

    # Public: Initialize an empty configuration for this gear
    #
    # Examples
    #
    #    create
    #    # => nil
    #    # directory for httpd configuration.
    #
    # Returns nil on Success or raises on Failure
    def create
      basedir = @config.get("GEAR_BASE_DIR")

      token = "#{@container_uuid}_#{@namespace}_#{@container_name}"
      path = File.join(basedir, ".httpd.d", token)

      FileUtils.rm_rf(path) if File.exist?(path)
      FileUtils.mkdir_p(path)      
    end

    # Public: Remove the frontend httpd configuration for a gear.
    #
    # Examples
    #
    #    destroy
    #    # => nil
    #
    # Returns nil on Success or raises on Failure
    def destroy(async=true)
      basedir = @config.get("GEAR_BASE_DIR")

      path = File.join(basedir, ".httpd.d", "#{container_uuid}_*")
      FileUtils.rm_rf(Dir.glob(path))

      reload_all(async)
    end

    # Public: Connect a path element to a back-end URI for this namespace.
    #
    # Examples
    #
    #     connect('/', 'http://127.0.250.1:8080/')
    #     connect('/phpmyadmin, ''http://127.0.250.2:8080/')
    #     connect('/socket, 'http://127.0.250.3:8080/', {:websocket=>1}
    #
    #     # => nil
    #
    # Returns nil on Success or raises on Failure
    def connect(path, uri, options={})
      raise NotImplementedError
    end

    # Public: Disconnect a path element from this namespace
    #
    # Examples
    #
    #     disconnect('/')
    #     disconnect('/phpmyadmin)
    #
    #     # => nil
    #
    # Returns nil on Success or raises on Failure
    def disconnect(path)
      raise NotImplementedError
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
      path = server_alias_path(dname)

      # Aliases must be globally unique across all gears.
      existing = server_alias_search(dname, true)
      if not existing.empty?
        raise FrontendHttpServerAliasException.new("Already exists", @container_uuid, \
                                                   @container_name, @namespace, dname )
      end

      File.open(path, "w") do |f|
        f.write("ServerAlias #{dname}")
        f.flush
      end

      create_routes_alias(dname)

      reload_all
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
      routes_file_path = server_routes_alias_path(dname)

      FileUtils.rm_f(routes_file_path) if File.exist?(routes_file_path)

      server_alias_search(dname, false).each do |path|
        FileUtils.rm_f(path)
      end

      #
      # Cleanup for alias specific configuration
      # 
      basedir = @config.get("GEAR_BASE_DIR")
      alias_token = "#{@container_uuid}_#{@namespace}_#{dname}"

      alias_conf_dir_path = File.join(basedir, ".httpd.d", alias_token)
      alias_conf_file_path = File.join(basedir, ".httpd.d", "#{alias_token}.conf")

      # Remove alias specific configuration and certs on the gear
      FileUtils.rm_f(alias_conf_file_path)
      FileUtils.rm_rf(alias_conf_dir_path)

      reload_all
    end

    # Public: Adds a ssl certificate for an alias
    def add_ssl_cert(ssl_cert, ssl_cert_name, priv_key, priv_key_name,
                     server_alias)
      basedir = @config.get("GEAR_BASE_DIR")

      app_token = "#{@container_uuid}_#{@namespace}_#{@container_name}"
      alias_token = "#{@container_uuid}_#{@namespace}_#{server_alias}"

      app_conf_dir_path = File.join(basedir, ".httpd.d", app_token)
      alias_conf_dir_path = File.join(basedir, ".httpd.d", alias_token)
      ssl_cert_file_path = File.join(alias_conf_dir_path, ssl_cert_name)
      priv_key_file_path = File.join(alias_conf_dir_path, priv_key_name)

      # Check if the specified alias has been created for the app
      server_alias_conf_file_path = File.join(app_conf_dir_path, "server_alias-#{server_alias}.conf")
      
      unless File.exists? (server_alias_conf_file_path)
        raise FrontendHttpServerException.new("Specified alias #{server_alias} does not exist for the app",
                                              @container_uuid, @container_name,
                                              @namespace)
      end

      # Make sure that the private key is not encrypted
      if priv_key.include? "ENCRYPTED"
        raise FrontendHttpServerException.new("Private key is encrypted",
                                              @container_uuid, @container_name,
                                              @namespace)
      end

      # Create a new directory for the alias and copy the certificates
      FileUtils.mkdir_p(alias_conf_dir_path)
      File.open(ssl_cert_file_path, 'w') { |f| f.write(ssl_cert) }
      File.open(priv_key_file_path, 'w') { |f| f.write(priv_key) }

      # Verify the cert and the key
      rc, out, errout = systemu "openssl rsa -in #{priv_key_file_path}"
      if rc != 0
        FileUtils.rm_f(ssl_cert_file_path)
        FileUtils.rm_f(priv_key_file_path)
        FileUtils.rm_f(alias_conf_dir_path)
        raise FrontendHttpServerException.new("Invalid private key",
                                              @container_uuid, @container_name,
                                              @namespace)
      end

      rc, out, errout = systemu "openssl x509 -in #{ssl_cert_file_path} -text -noout"
      if rc != 0
        FileUtils.rm_f(ssl_cert_file_path)
        FileUtils.rm_f(priv_key_file_path)
        FileUtils.rm_f(alias_conf_dir_path)
        raise FrontendHttpServerException.new("Invalid ssl certificate",
                                              @container_uuid, @container_name,
                                              @namespace)
      end

      #
      # Create configuration for the alias
      #

      # Create 00000_default.conf for the alias
      default_conf_contents = <<-DEFAULT_ENTRY
ServerName #{server_alias}
ServerAdmin openshift-bofh@redhat.com
DocumentRoot /var/www/html
DefaultType None
      DEFAULT_ENTRY

      default_conf_file_path = File.join(alias_conf_dir_path, "00000_default.conf")
      File.open(default_conf_file_path, 'w') { |f| f.write(default_conf_contents) }

      # Copy zzzzz_proxy.conf for the alias
      proxy_conf_file_src_path = File.join(app_conf_dir_path, "zzzzz_proxy.conf")
      FileUtils.cp(proxy_conf_file_src_path, alias_conf_dir_path)

      # Create top level config file for the alias
      alias_conf_contents = <<-ALIAS_CONF_ENTRY
<VirtualHost *:80>
  RequestHeader append X-Forwarded-Proto "http"

  Include #{alias_conf_dir_path}/*.conf
</VirtualHost>

<VirtualHost *:443>
  RequestHeader append X-Forwarded-Proto "https"

# This file gets inserted into every httpd.conf ssl section
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

  RequestHeader set X-Forwarded-SSL-Client-Cert %{SSL_CLIENT_CERT}e

  Include #{alias_conf_dir_path}/*.conf
</VirtualHost>
      ALIAS_CONF_ENTRY

      alias_conf_file_path = File.join(basedir, ".httpd.d", "#{alias_token}.conf")
      File.open(alias_conf_file_path, 'w') { |f| f.write(alias_conf_contents) }

      # Remove original server alias conf file
      FileUtils.rm_f(server_alias_conf_file_path)

      # Reload httpd to pick up the new configuration
      reload_httpd
    end

    # Public: Removes ssl certificate/private key associated with an alias
    def remove_ssl_cert(ssl_cert_name, priv_key_name, server_alias)
      basedir = @config.get("GEAR_BASE_DIR")

      #
      # Remove the alias specific configuration
      #
      app_token = "#{@container_uuid}_#{@namespace}_#{@container_name}"
      alias_token = "#{@container_uuid}_#{@namespace}_#{server_alias}"

      app_conf_dir_path = File.join(basedir, ".httpd.d", app_token)
      alias_conf_dir_path = File.join(basedir, ".httpd.d", alias_token)
      #ssl_cert_file_path = File.join(alias_conf_dir_path, ssl_cert_name)
      #priv_key_file_path = File.join(alias_conf_dir_path, priv_key_name)
      alias_conf_file_path = File.join(basedir, ".httpd.d", "#{alias_token}.conf")

      #FileUtils.rm_rf(ssl_cert_file_path)
      #FileUtils.rm_rf(priv_key_file_path)
      FileUtils.rm_rf(alias_conf_file_path)
      FileUtils.rm_rf(alias_conf_dir_path)

      # Re-create original server alias conf file
      server_alias_conf_contents = <<-SERVER_ALIAS_ENTRY
ServerAlias #{server_alias}
      SERVER_ALIAS_ENTRY

      server_alias_conf_file_path = File.join(app_conf_dir_path, "server_alias-#{server_alias}.conf")
      File.open(server_alias_conf_file_path, 'w') { |f| f.write(server_alias_conf_contents) }

      # Reload httpd to pick up the configuration changes
      reload_httpd
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

    # Private: Return path to alias file
    def server_alias_path(name)
      dname = clean_server_name(name)

      basedir = @config.get("GEAR_BASE_DIR")
      token = "#{@container_uuid}_#{@namespace}_#{@container_name}"
      path = File.join(basedir, '.httpd.d', token, "server_alias-#{dname}.conf")
    end

    # Private: Return path to routes alias file name used by ws proxy server
    def server_routes_alias_path(name)
      dname = clean_server_name(name)

      basedir = @config.get("GEAR_BASE_DIR")
      token = "#{@container_uuid}_#{@namespace}_#{@container_name}"
      path = File.join(basedir, '.httpd.d', token, "routes_alias-#{dname}.json")
    end

    # Get path to the default routes.json file created for the node web proxy
    def default_routes_path
      basedir = @config.get("GEAR_BASE_DIR")
      token = "#{@container_uuid}_#{@namespace}_#{@container_name}"
      File.join(basedir, '.httpd.d', token, "routes.json")
    end

    # Create an alias routing file for the node web proxy server
    def create_routes_alias(alias_name)
      route_file = default_routes_path
      alias_file = File.join(File.dirname(route_file), "routes_alias-#{alias_name}.json")

      begin
        File.open(route_file, 'r') do |fin|
          File.open(alias_file, 'w') do |fout|
            fout.write(fin.read.gsub("#{@container_name}-#{@namespace}.#{@cloud_domain}", "#{alias_name}"))
          end
        end
      rescue => e
        Syslog.alert("ERROR: Failure trying to create routes alias json file: #{@uuid} Exception: #{e.inspect}")
      end
    end

    # Reload both Apache and the proxy server and combine output/return
    def reload_all(async=false)
      output = ''
      errout = ''
      retc = 0

      out, err, rc = reload_node_web_proxy
      output << out
      errout << err
      retc = rc if rc != 0

      out, err, rc = reload_httpd(async)
      output << out
      errout << err
      retc = rc if rc != 0

      return output, errout, retc
    end

    # Reload the Apache configuration
    def reload_httpd(async=false)
      async_opt="-b" if async
      out, err, rc = shellCmd("/usr/sbin/oo-httpd-singular #{async_opt} graceful")
      Syslog.alert("ERROR: failure from oo-httpd-singular(#{rc}): #{@uuid} stdout: #{out} stderr:#{err}") unless rc == 0
      return out, err, rc
    end

    # Reload the configuration of the node web proxy server
    def reload_node_web_proxy
      out, err, rc = shellCmd("service openshift-node-web-proxy reload")
      Syslog.alert("ERROR: failure from openshift-node-web-proxy(#{rc}): #{@uuid} stdout: #{out} stderr:#{err}") unless rc == 0
      return out, err, rc
    end

    # Private: Search for matching alias files
    # Previously, case sensitive matches were used
    # checking for a duplicate and there are mixed
    # case aliases in use.
    def server_alias_search(name, all_gears=false)
      dname = clean_server_name(name)
      resp = []

      basedir = @config.get("GEAR_BASE_DIR")
      if all_gears
        token = "*"
      else
        token = "#{@container_uuid}_#{@namespace}_#{@container_name}"
      end
      srch = File.join(basedir, ".httpd.d", token, "server_alias-*.conf")
      Dir.glob(srch).each do |fn|
        cmpname = fn.sub(/^.*\/server_alias-(.*)\.conf$/, '\\1')
        if cmpname.casecmp(dname) == 0
          resp << fn
        end
      end
      resp
    end

  end

end
