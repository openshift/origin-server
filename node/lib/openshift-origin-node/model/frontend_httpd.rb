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

      reload_node_web_proxy

      async_opt="-b" if async
      out, err, rc = shellCmd("/usr/sbin/oo-httpd-singular #{async_opt} graceful")
      Syslog.alert("ERROR: failure from oo-httpd-singular(#{rc}): #{@uuid} stdout: #{out} stderr:#{err}") unless rc == 0
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

      # Aliases must be globally unique across all gears (approx 5 seconds for 20000 gears)
      existing = Dir.glob(File.join(@config.get("GEAR_BASE_DIR"), ".httpd.d", "*/server_alias-#{dname}.conf"))
      if not existing.empty?
        raise FrontendHttpServerAliasException.new("Already exists", @container_uuid, \
                                                   @container_name, @namespace, dname )
      end

      File.open(path, "w") do |f|
        f.write("ServerAlias #{dname}")
        f.flush
      end

      create_routes_alias(dname)
      reload_node_web_proxy

      out, err, rc = shellCmd("/usr/sbin/oo-httpd-singular graceful")
      Syslog.alert("ERROR: failure from oo-httpd-singular(#{rc}): #{@uuid} stdout: #{out} stderr:#{err}") unless rc == 0

      return out, err, rc
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
      path = server_alias_path(dname)
      routes_file_path = server_routes_alias_path(dname)

      FileUtils.rm_f(path) if File.exist?(path)
      FileUtils.rm_f(routes_file_path) if File.exist?(routes_file_path)

      reload_node_web_proxy

      out, err, rc = shellCmd("/usr/sbin/oo-httpd-singular graceful")
      Syslog.alert("ERROR: failure from oo-httpd-singular(#{rc}): #{@uuid} stdout: #{out} stderr:#{err}") unless rc == 0

      return out, err, rc
    end

    # Private: Return a cleaned version of the server name
    def clean_server_name(name)
      dname = name.downcase

      if not dname.index(/[^0-9a-z\-_.]/).nil?
        raise FrontendHttpServerNameException.new("Invalid characters", @container_uuid, \
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
      cmd = "sed 's/#{@container_name}-#{@namespace}\.#{@cloud_domain}/#{alias_name}/g' #{route_file} > #{alias_file}"

      out, err, rc = shellCmd(cmd)
      Syslog.alert("ERROR: Failure trying to create routes alias json file(#{rc}): #{@uuid} stdout: #{out} stderr:#{err}") unless rc == 0
    end

    # Reload the configuration of the node web proxy server
    def reload_node_web_proxy
      out, err, rc = shellCmd("service openshift-node-web-proxy reload")
      Syslog.alert("ERROR: failure from openshift-node-web-proxy(#{rc}): #{@uuid} stdout: #{out} stderr:#{err}") unless rc == 0
    end
  end

end
