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

require 'json'
require 'openshift-origin-node/utils/node_logger'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash'

module OpenShift
  module Runtime
    class GearRegistry
      include NodeLogger

      # Represents an individual entry in the gear registry
      class Entry
        attr_reader :uuid, :namespace, :dns, :proxy_ip, :proxy_port

        def initialize(options)
          @uuid = options[:uuid]
          @namespace = options[:namespace]
          @dns = options[:dns]
          @proxy_ip = options[:proxy_ip]
          @proxy_port = options[:proxy_port]
        end

        def as_json(options={})
          {namespace: @namespace, dns: @dns, proxy_ip: @proxy_ip, proxy_port: @proxy_port}
        end
      end

      # Creates gear_registry.{lock,json} if they don't exist and sets the perms appropriately and
      # loads the gear registry from disk
      def initialize(container)
        @container = container

        @registry_file = PathUtils.join(@container.container_dir, 'gear_registry.json')
        unless File.exist?(@registry_file)
          File.new(@registry_file, "w", 0o0644)
          @container.set_rw_permission(@registry_file)
        end

        @lock_file = PathUtils.join(@container.container_dir, 'gear_registry.lock')
        unless File.exist?(@lock_file)
          File.new(@lock_file, "w", 0o0644)
          @container.set_rw_permission(@lock_file)
        end

        load
      end

      # Returns a copy of the gear registry's entries.
      #
      # Changes to the copy will NOT be reflected in the GearRegistry itself
      def entries
        Marshal.load(Marshal.dump(@gear_registry))
      end

      def clear
        @gear_registry = {}
      end

      def add(options)
        # make sure all required fields are passed in
        %w(type uuid namespace dns proxy_ip proxy_port).map(&:to_sym).each { |s| raise "#{s} is required" if options[s].nil?}

        # add entry to registry by type
        type = options[:type].to_sym
        @gear_registry[type] ||= {}
        @gear_registry[type][options[:uuid]] = Entry.new(options)
      end

      # Reads the gear registry from disk
      #
      # The gear registry is stored in JSON and has the following format:
      #
      # {
      #  "web": {
      #    "522916bf6d909865c8000313": {
      #      "namespace": "foo",
      #      "dns": "myapp-foo.example.com",
      #      "proxy_ip": "52.1.2.3",
      #      "proxy_port": 35561
      #    },
      #    ...
      #  },
      #  "proxy": {
      #    ...
      #  }
      # }
      def load
        clear

        with_lock do
          File.open(@registry_file, "r") do |f|
            raw_json = HashWithIndifferentAccess.new(JSON.load(f))
            raw_json.each_pair do |type, entries|
              entries.each_pair do |uuid, entry|
                add(entry.merge({type: type.to_sym, uuid: uuid}))
              end
            end
          end
        end
      end

      # Writes the gear registry to disk
      def save
        with_lock do
          File.open(@registry_file, "w") { |f| f.write JSON.dump(self) }
        end
      end

      def as_json(options={})
        @gear_registry.as_json(options)
      end

      private

      # Work with the gear registry file while a lock is held
      def with_lock
        File.open(@lock_file, "w") do |lock|
          begin
            lock.flock(File::LOCK_EX)
            yield
          ensure
            lock.flock(File::LOCK_UN)
          end
        end
      end
    end
  end
end
