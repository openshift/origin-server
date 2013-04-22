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
require 'openshift-origin-node/utils/environ'
require 'openshift-origin-node/model/application_repository'

module OpenShift
  class DefaultBuilder
    def initialize(application_container)
      @container = application_container
    end

    def pre_receive(options)
      if options[:hot_deploy]
        options[:out].puts "Skipping gear stop due to presence of hot deploy marker" if options[:out]
      else
        @container.stop_gear(user_initiated: true,
                             out: options[:out],
                             err: options[:err])
      end
    end

    def post_receive(options)
      ApplicationRepository.new(@container.user).deploy

      @container.build(out: options[:out],
                       err: options[:err])

      if options[:hot_deploy]
        options[:out].puts "Skipping secondary gear start due to presence of hot deploy marker" if options[:out]
      else
        @container.start_gear(secondary_only: true,
                              user_initiated: true,
                              out:            options[:out],
                              err:            options[:err])
      end

      @container.deploy(out: options[:out],
                        err: options[:err])

      if options[:hot_deploy]
        options[:out].puts "Skipping primary gear start due to presence of hot deploy marker" if options[:out]
      else
        @container.start_gear(primary_only:   true,
                              user_initiated: true,
                              out:            options[:out],
                              err:            options[:err])
      end

      @container.post_deploy(out: options[:out],
                             err: options[:err])
    end
  end
end
