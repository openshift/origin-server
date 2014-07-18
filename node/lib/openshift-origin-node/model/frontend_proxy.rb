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
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-common'
require 'syslog'
require 'fileutils'

module OpenShift
  module Runtime
    class FrontendProxyServerException < StandardError
      attr_reader :uid

      def initialize(msg=nil, uid=nil)
        @uid = uid
        super(msg)
      end

      def to_s
        m = super
        m+= ": uid=#{@uid}" if not @uid.nil?
        m
      end
    end

    # == Frontend Proxy Server
    #
    # Represents the front-end proxy server on the system. Upon initialization,
    # defaults necessary to compute ranges are extracted from Openshift::Config.
    #
    # Note: This is the HAProxy implementation; other implementations may vary.
    class FrontendProxyServer
      include NodeLogger

      def initialize
        # Extract config values and compute the port range this proxy
        # instance should act upon, relative to the given container/user.
        config = ::OpenShift::Config.new

        @port_begin = (config.get("PORT_BEGIN") || "35531").to_i
        @ports_per_user = (config.get("PORTS_PER_USER") || "5").to_i
        @uid_begin = (config.get("UID_BEGIN") || "500").to_i
      end

      # Returns a Range representing the valid proxy port values for the
      # given UID.
      #
      # The port proxy range is determined by configuration and must
      # produce identical results to the abstract cartridge provided
      # range.
      #
      # Note, due to a mismatch between dev and prod this is
      # intentionally not GEAR_MIN_UID and the range must
      # wrap back around on itself.
      def port_range(uid)
        proxy_port_begin = (uid - @uid_begin) % ((65536 - @port_begin) / @ports_per_user) * @ports_per_user + @port_begin
        (proxy_port_begin ... (proxy_port_begin + @ports_per_user))
      end

      # Deletes an existing proxy mapping for the specified UID, IP and port.
      #
      # Returns nil on success or a FrontendProxyServerException on failure.
      def delete(uid, ip, port)
        raise "No UID specified" if uid == nil
        raise "No IP specified" if ip == nil
        raise "No port specified" if port == nil
        raise "Invalid port specified" unless port.is_a? Integer

        target_addr = "#{ip}:#{port}"

        mapped_proxy_port = find_mapped_proxy_port(uid, ip, port)

        # No existing mapping, nothing to do.
        return if mapped_proxy_port == nil

        out, err, rc = system_proxy_delete(mapped_proxy_port)

        if rc != 0
          raise FrontendProxyServerException.new(
                    "System proxy failed to delete #{mapped_proxy_port} => #{target_addr}(#{rc}): stdout: #{out} stderr: #{err}", uid)
        end
      end

      # Deletes any existing proxy ports associated with the given UID.
      #
      # If ignore_errors is specified, any delete attempts will be logged
      # and ignored. Otherwise, any exception will be immediately be re-raised.
      #
      # Returns nil on success.
      def delete_all_for_uid(uid, ignore_errors=true)
        raise "No UID specified" if uid == nil

        proxy_ports = []

        port_range(uid).each { |proxy_port| proxy_ports << proxy_port }

        delete_all(proxy_ports, ignore_errors)
      end

      # Deletes all proxy ports in the specified array.
      #
      # If ignore_errors is specified, any delete attempts will be logged
      # and ignored. Otherwise, any exception will be immediately be re-raised.
      #
      # Returns the exit code from the call to system_proxy_delete if no
      # exception is raised.
      def delete_all(proxy_ports, ignore_errors=true)
        raise "No proxy ports specified" if proxy_ports == nil

        out, err, rc = system_proxy_delete(*proxy_ports)

        if (rc != 0)
          message = "System proxy delete of port(s) #{proxy_ports} failed(#{rc}): stdout: #{out} stderr: #{err}"
          if ignore_errors
            logger.warn(message)
          else
            raise FrontendProxyServerException.new(message)
          end
        end

        return rc
      end

      # Adds a new proxy mapping for the specified UID, IP and target port
      # using the next available proxy port in the user's range.
      #
      # Returns an Integer value for the mapped proxy port on success. Raises a
      # FrontendProxyServerException if the mapping attempt fails or if no ports
      # are left available to map.
      def add(uid, ip, port)
        raise "No UID specified" if uid == nil
        raise "No IP specified" if ip == nil
        raise "No port specified" if port == nil
        raise "Invalid port specified" unless port.is_a? Integer

        requested_addr = "#{ip}:#{port}"

        port_range(uid).each do |proxy_port|
          # Get the existing mapped address for this proxy port
          current_addr = system_proxy_show(proxy_port)

          # If there's already a mapping for this proxy port, return
          # the existing mapping if it matches the request, otherwise
          # skip it as being already in use
          if current_addr != nil
            if current_addr == requested_addr
              return proxy_port
            else
              next
            end
          end

          # No existing mapping exists, so attempt to create one
          out, err, rc = system_proxy_set({:proxy_port => proxy_port, :addr => requested_addr})

          if rc != 0
            raise FrontendProxyServerException.new(
                      "System proxy set for #{proxy_port}=>#{requested_addr} failed(#{rc}): stdout: #{out} stderr: #{err}", uid)
          end

          return proxy_port
        end

        raise FrontendProxyServerException.new("No ports were left available to map #{requested_addr}", uid)
      end

      # Find the proxy port for a given UID, IP and target port.
      #
      # Examples:
      #
      #   find_mapped_proxy_port(500, '127.0.0.1', 8080)
      #   => 35531
      #
      # Returns the proxy port if found, otherwise nil.
      def find_mapped_proxy_port(uid, ip, port)
        raise "No UID specified" if uid == nil
        raise "No IP specified" if ip == nil
        raise "No port specified" if port == nil
        raise "Invalid port specified" unless port.is_a? Integer

        target_addr = "#{ip}:#{port}"

        mapped_proxy_port = nil

        port_range(uid).each do |proxy_port|
          current_addr = system_proxy_show(proxy_port)

          if current_addr == target_addr
            mapped_proxy_port = proxy_port
            break
          end
        end

        return mapped_proxy_port
      end

      # System interface to delete one or more proxy entries.
      #
      # Example:
      #
      #     system_proxy_delete(30000)
      #     => [out, err, rc]
      #
      #     system_proxy_delete(30000, 30001, 30002)
      #     => [out, err, rc]
      def system_proxy_delete(*ports)
        if ports != nil && ports.length > 0
          cmd = %{oo-iptables-port-proxy removeproxy}
          ports.each { |port| cmd << " #{port}" }

          out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn(cmd)
          return out, err, rc
        else
          return nil, nil, 0
        end
      end

      # System interface to set a proxy entry. Expects a varargs
      # array of hashes with keys :proxy_port and :addr representing
      # a mapping entry.
      #
      # Example:
      #
      #     system_proxy_set({:proxy_port => 30000, :addr => "127.0.0.1:8080"})
      #     => [out, err, rc]
      #
      #     system_proxy_set(
      #       {:proxy_port => 30000, :addr => "127.0.0.1:8080"},
      #       {:proxy_port => 30001, :addr => "127.0.0.1:8081"}
      #     )
      #     => [out, err, rc]
      def system_proxy_set(*mappings)
        if mappings != nil && mappings.length > 0
          cmd = %{oo-iptables-port-proxy addproxy}
          mappings.each { |mapping| cmd << %Q{ #{mapping[:proxy_port]} "#{mapping[:addr]}"} }

          out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn(cmd)
          return out, err, rc
        else
          return nil, nil, 0
        end
      end

      # System interface to show an existing proxy entry.
      def system_proxy_show(proxy_port)
        raise "No proxy port specified" unless proxy_port != nil

        target, err, rc = ::OpenShift::Runtime::Utils::oo_spawn(%{oo-iptables-port-proxy showproxy #{proxy_port} | awk '{ print $2 }'})
        target.chomp!

        return target.length > 0 ? target : nil
      end
    end
  end
end
