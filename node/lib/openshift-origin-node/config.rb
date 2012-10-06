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
require 'singleton'
require 'parseconfig'

module OpenShift
  # == OpenShift Config
  #
  # Allows access to node.config file.
  #
  # Reads config entried for the sdk from /etc/openshift/node.conf and if
  # that is not available then it will read it from conf/node.conf 
  # within the ruby gem.
  class Config
    include Object::Singleton

    CONF_NAME = 'node.conf'
    CONF_DIR = '/etc/openshift/'
    
    def initialize()
      _linux_cfg = File.join(CONF_DIR,CONF_NAME)
      _gem_cfg = File.join(File.expand_path(File.dirname(__FILE__) + 
            '/../../conf'), CONF_NAME)
      @config_path = File.exists?(_linux_cfg) ? _linux_cfg : _gem_cfg

      begin
        @@global_config = ParseConfig.new(@config_path)
      rescue Errno::EACCES => e
        puts "Could not open config file: #{e.message}"
        exit 253
      end
    end

    def get(name)
      val = @@global_config.get_value(name)
      val.gsub!(/\\:/,":") if not val.nil?
      val.gsub!(/[ \t]*#[^\n]*/,"") if not val.nil?
      val = val[1..-2] if not val.nil? and val.start_with? "\""
      val
    end
  end
end
