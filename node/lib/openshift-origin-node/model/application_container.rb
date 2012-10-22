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
require 'openshift-origin-node/model/unix_user'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-common'

module OpenShift
  # == Application Container
  class ApplicationContainer < Model
    include OpenShift::Utils::ShellExec
    attr_reader :uuid, :application_uuid, :user

    def initialize(application_uuid, container_uuid, user_uid = nil,
        app_name = nil, container_name = nil, namespace = nil, quota_blocks = nil, quota_files = nil)
      @config = OpenShift::Config.new

      @uuid = container_uuid
      @application_uuid = application_uuid
      @user = UnixUser.new(application_uuid, container_uuid, user_uid,
        app_name, container_name, namespace, quota_blocks, quota_files)
    end

    def name
      @uuid
    end

    # Create gear - model/unix_user.rb
    def create
      notify_observers(:before_container_create)
      @user.create
      notify_observers(:after_container_create)
    end

    # Destroy gear - model/unix_user.rb
    def destroy(skip_hooks=false)
      notify_observers(:before_container_destroy)

      hook_timeout=30

      output = ""
      errout = ""
      retcode = 0

      hooks={}
      ["pre", "post"].each do |hooktype|
        if @user.homedir.nil? || ! File.exists?(@user.homedir)
          hooks[hooktype]=[]
        else
          hooks[hooktype] = Dir.entries(@user.homedir).map { |cart|
            [ File.join(@config.get("CARTRIDGE_BASE_PATH"),cart,"info","hooks","#{hooktype}-destroy"),
              File.join(@config.get("CARTRIDGE_BASE_PATH"),"embedded",cart,"info","hooks","#{hooktype}-destroy"),
            ].select { |hook| File.exists? hook }[0]
          }.select { |hook|
            not hook.nil?
          }.map { |hook|
            "#{hook} #{@user.container_name} #{@user.namespace} #{@user.container_uuid}"
          }
        end
      end

      unless skip_hooks
        hooks["pre"].each do | cmd |
          out,err,rc = shellCmd(cmd, "/", true, 0, hook_timeout)
          errout << err if not err.nil?
          output << out if not out.nil?
          retcode = 121 if rc != 0
        end
      end

      @user.destroy

      unless skip_hooks
        hooks["post"].each do | cmd |
          out,err,rc = shellCmd(cmd, "/", true, 0, hook_timeout)
          errout << err if not err.nil?
          output << out if not out.nil?
          retcode = 121 if rc != 0
        end
      end

      notify_observers(:after_container_destroy)

      return output, errout, retcode
    end

    # Public: Fetch application state from gear.
    # Returns app state as string on Success and 'unknown' on Failure
    def get_app_state
      env = load_env
      app_state_file=File.join(env[:OPENSHIFT_HOMEDIR], 'app-root', 'runtime', '.state')
      
      if File.exists?(app_state_file)
        app_state = nil
        File.open(app_state_file) { |input| app_state = input.read.chomp }
      else
        app_state = 'unknown'
      end
      app_state
    end

    # Public: Load a gears environment variables into the environment
    #
    # Examples
    #
    #   load_env
    #   # => {"OPENSHIFT_APP_NAME"=>"myapp"}
    #
    # Returns env Array
    def load_env
      env = {}
      # Load environment variables into a hash
      
      Dir["#{user.homedir}/.env/*"].each { | f |
        next if File.directory?(f)
        contents = nil
        File.open(f) {|input|
          contents = input.read.chomp
          index = contents.index('=')
          contents = contents[(index + 1)..-1]
          contents = contents[/'(.*)'/, 1] if contents.start_with?("'")
          contents = contents[/"(.*)"/, 1] if contents.start_with?('"')
        }
        env[File.basename(f).intern] =  contents
      }
      env
    end
  end
end
