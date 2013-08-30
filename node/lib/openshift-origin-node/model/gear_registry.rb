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

require 'openshift-origin-node/utils/node_logger'

module OpenShift
  module Runtime
    class GearRegistry
      include NodeLogger

      # Represents an individual entry in the gear registry
      class Entry
        attr_reader :uuid, :namespace, :dns, :private_ip, :proxy_port

        def initialize(options)
          @uuid = options[:uuid]
          @namespace = options[:namespace]
          @dns = options[:dns]
          @private_ip = options[:private_ip]
          @proxy_port = options[:proxy_port]
        end

        # Used when writing to the gear registry file
        def to_s
          "#{@uuid},#{@namespace},#{@dns},#{@private_ip},#{@proxy_port}"
        end

        def ==(other)
          uuid == other.uuid and
          namespace == other.namespace and
          dns == other.dns and
          private_ip == other.private_ip and
          proxy_port == other.proxy_port
        end
      end

      # Creates gear_registry.{lock,txt} if they don't exist and sets the perms appropriately and
      # loads the gear registry from disk
      def initialize(container)
        @container = container

        @registry_file = PathUtils.join(@container.container_dir, 'gear_registry.txt')
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
        @gear_registry.dup
      end

      # Updates gear_registry.txt to contain only those values specified by the entries param
      #
      # Returns an Array of just the Entry instances that are newly added
      def update(entries)
        new_gears = entries.values.select { |entry| not @gear_registry.keys.include?(entry.uuid) }

        @gear_registry = entries
        save
        new_gears
      end

      # Returns an array of all the gears' SSH URLs
      def ssh_urls
        @gear_registry.values.map { |e| "#{e.uuid}@#{e.dns}" }
      end

      # Reads the gear registry from disk
      def load
        @gear_registry = {}
        with_lock do
          File.open(@registry_file, "r") do |f|
            while line = f.gets
              uuid, namespace, dns, private_ip, proxy_port = line.chomp.split(',')
              @gear_registry[uuid] = Entry.new(uuid: uuid,
                                               namespace: namespace,
                                               dns: dns,
                                               private_ip: private_ip,
                                               proxy_port: proxy_port)
            end
          end
        end
      end

      # Writes the gear registry to disk
      def save
        with_lock do
          File.open(@registry_file, "w") do |f|
            @gear_registry.values.each do |entry|
              f.puts "#{entry}\n"
            end
          end
        end
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