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

require 'rubygems'
require 'openshift-origin-common'

module OpenShift
  #load OPENSHIFT_NODE_PLUGINS
  plugin_list = []

  begin
    config = Config.new
    if config
      plugins = config.get('OPENSHIFT_NODE_PLUGINS')
      plugin_list = plugins.split(',') if plugins
    end
  rescue => e
    puts "Warning: Couldn't load plugin list for environment: #{e.message}"
  end

  plugin_list.each do |plugin|
    begin
      require "#{plugin}" unless plugin.start_with?('#')
    rescue => e
      raise "Error loading environment plugin '#{plugin}': #{e.message}"
    end
  end
end
