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

module OpenShift
  class Config
    CONF_DIR = '/etc/openshift/'
    PLUGINS_DIR = File.join(CONF_DIR, 'plugins.d/')
    NODE_CONF_FILE = File.join(CONF_DIR, 'node.conf')

    def initialize(conf_path=NODE_CONF_FILE)
      begin
        @conf = ParseConfig.new(conf_path)
      rescue Errno::EACCES => e
        puts "Could not open config file #{conf_path}: #{e.message}"
        exit 253
      end
    end

    def get(name)
      val = @conf.get_value(name)
      val.gsub!(/\\:/,":") if not val.nil?
      val.gsub!(/[ \t]*#[^\n]*/,"") if not val.nil?
      val = val[1..-2] if not val.nil? and val.start_with? "\""
      val
    end

    def get_bool(name)
      # !! is used to normalise the value to either a 1 (true) or a 0 (false).
      !!(get(name) =~ /^(true|t|yes|y|1)$/i)
    end
  end
end
