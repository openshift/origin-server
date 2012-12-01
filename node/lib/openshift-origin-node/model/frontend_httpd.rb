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

module OpenShift
  
  class FrontendHttpServerException < StandardError; end
  class FrontendHttpServerNameException < FrontendHttpServerException; end
  class FrontendHttpServerPathException < FrontendHttpServerException; end
  class FrontendHttpServerAliasException < FrontendHttpServerException; end
  
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
        raise FrontendHttpServerAliasException.new("Server alias already exists: #{dname}")
      end

      File.open(path, "w") do |f|
        f.write("ServerAlias #{dname}")
        f.flush
      end

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

      FileUtils.rm_f(path) if File.exist?(path)

      out, err, rc = shellCmd("/usr/sbin/oo-httpd-singular graceful")
      Syslog.alert("ERROR: failure from oo-httpd-singular(#{rc}): #{@uuid} stdout: #{out} stderr:#{err}") unless rc == 0

      return out, err, rc
    end


    # Private: Return a cleaned version of the server name
    def clean_server_name(name)
      dname = name.downcase

      if not dname.index(/[^0-9a-z\-_.]/).nil?
        raise FrontendHttpServerNameException.new("Server alias contains invalid characters: #{dname}")
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

  end

end
