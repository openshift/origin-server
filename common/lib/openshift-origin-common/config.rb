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
require 'parseconfig'
require 'openshift-origin-common/utils/path_utils'

module OpenShift
  class Config
    CONF_DIR = ENV['OPENSHIFT_CONF_DIR'] || '/etc/openshift/'
    PLUGINS_DIR = PathUtils.join(CONF_DIR, 'plugins.d/')
    NODE_CONF_FILE = PathUtils.join(CONF_DIR, 'node.conf')

    @@conf_parsed = {}
    @@conf_mtime  = {}

    def initialize(conf_path=NODE_CONF_FILE, default={})
      if conf_path
        begin
          conf_mtime = File.stat(conf_path).mtime
          if @@conf_parsed[conf_path].nil? or (conf_mtime != @@conf_mtime[conf_path])
            @@conf_parsed[conf_path] = ParseConfig.new(conf_path)
            @@conf_mtime[conf_path] = conf_mtime
          end
          @conf = @@conf_parsed[conf_path]
        rescue Errno::EACCES => e
          puts "Could not open config file #{conf_path}: #{e.message}"
          exit 253
        end
      else
        @conf = ParseConfig.new
        @conf.params = default
      end
    end

    def get(name, default=nil)
      val = @conf[name]
      val = default.to_s if (val.nil? and !default.nil?)
      val.gsub!(/\\:/,":") if not val.nil?
      val.gsub!(/[ \t]*#[^\n]*/,"") if not val.nil?
      val = val[1..-2] if not val.nil? and val.start_with? "\""
      val = val[1..-2] if not val.nil? and val.start_with? "\'"
      val
    end

    def get_bool(name, default=nil)
      # !! is used to normalize the value to either a 1 (true) or a 0 (false).
      !!(get(name, default) =~ /^(true|t|yes|y|1)$/i)
    end

    def get_group(name, default={})
      if @conf.groups.include?(name)
        self.class.new(nil, @conf[name])
      else
        self.class.new(nil, default)
      end
    end

    def params
      @conf.get_params
    end

    def groups
      @conf.get_groups
    end

  end
end
