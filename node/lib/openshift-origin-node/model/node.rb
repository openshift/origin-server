#--
# Copyright 2012 Red Hat, Inc.
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

require 'openshift-origin-node'
require 'openshift-origin-common'
require 'systemu'

module OpenShift
  class NodeCommandException < StandardError; end

  class Node < Model
    def self.get_cartridge_list(list_descriptors = false, porcelain = false, oo_debug = false)
      carts = []

      cartridge_path = OpenShift::Config.new.get("CARTRIDGE_BASE_PATH")
      Dir.foreach(cartridge_path) do |cart_dir|
        next if [".", "..", "embedded", "abstract", "abstract-httpd", "abstract-jboss"].include? cart_dir
        path = File.join(cartridge_path, cart_dir, "info", "manifest.yml")
        begin
          print "Loading #{cart_dir}..." if oo_debug
          carts.push OpenShift::Cartridge.new.from_descriptor(YAML.load(File.open(path)))
          print "OK\n" if oo_debug
        rescue Exception => e
          print "ERROR\n" if oo_debug
          print "#{e.message}\n#{e.backtrace.inspect}\n" unless porcelain
        end
      end

      print "\n\n\n" if oo_debug

      output = ""
      if porcelain
        if list_descriptors
          output << "CLIENT_RESULT: "
          output << carts.map{|c| c.to_descriptor.to_yaml}.to_json
        else
          output << "CLIENT_RESULT: "
          output << carts.map{|c| c.name}.to_json
        end
      else
        if list_descriptors
          carts.each do |c|
            output << "Cartridge name: #{c.name}\n\nDescriptor:\n #{c.to_descriptor.inspect}\n\n\n"
          end
        else
          output << "Cartridges:\n"
          carts.each do |c|
            output << "\t#{c.name}\n"
          end
        end
      end
      output
    end

    def self.get_cartridge_info(cart_name, porcelain = false, oo_debug = false)
      output = ""
      cart_found = false

      cartridge_path = OpenShift::Config.new.get("CARTRIDGE_BASE_PATH")
      Dir.foreach(cartridge_path) do |cart_dir|
        next if [".", "..", "embedded", "abstract", "abstract-httpd", "haproxy-1.4", "mysql-5.1", "mongodb-2.2", "postgresql-8.4"].include? cart_dir
        path = File.join(cartridge_path, cart_dir, "info", "manifest.yml")
        begin
          cart = OpenShift::Cartridge.new.from_descriptor(YAML.load(File.open(path)))
          if cart.name == cart_name
            output << "CLIENT_RESULT: "
            output << cart.to_descriptor.to_json
            cart_found = true
            break
          end
        rescue Exception => e
          print "ERROR\n" if oo_debug
          print "#{e.message}\n#{e.backtrace.inspect}\n" unless porcelain
        end
      end

      embedded_cartridge_path = File.join(cartridge_path, "embedded")
      if (! cart_found) and File.directory?(embedded_cartridge_path)
        Dir.foreach(embedded_cartridge_path) do |cart_dir|
          next if [".",".."].include? cart_dir
          path = File.join(embedded_cartridge_path, cart_dir, "info", "manifest.yml")
          begin
            cart = OpenShift::Cartridge.new.from_descriptor(YAML.load(File.open(path)))
            if cart.name == cart_name
              output << "CLIENT_RESULT: "
              output << cart.to_descriptor.to_json
              break
            end
          rescue Exception => e
            print "ERROR\n" if oo_debug
            print "#{e.message}\n#{e.backtrace.inspect}\n" unless porcelain
          end
        end
      end
      output
    end

    def self.get_quota(uuid)
      cmd = %&quota -w #{uuid} | awk '/^.*\\/dev/ {print $1":"$2":"$3":"$4":"$5":"$6":"$7}'; exit ${PIPESTATUS[0]}&
      st, out, errout = systemu cmd
      if st.exitstatus == 0 || st.exitstatus == 1
        arr = out.strip.split(":")
        raise NodeCommandException.new "Error: #{errout} executing command #{cmd}" unless arr.length == 7
        arr
      else
        raise NodeCommandException.new "Error: #{errout} executing command #{cmd}"
      end
    end

    def self.set_quota(uuid, blocksmax, inodemax)
      cur_quota = get_quota(uuid)
      inodemax = cur_quota[6] if inodemax.to_s.empty?
      
      mountpoint = %x[quota -w #{uuid} | awk '/^.*\\/dev/ {print $1}']
      cmd = "setquota -u #{uuid} 0 #{blocksmax} 0 #{inodemax} -a #{mountpoint}"
      st, out, errout = systemu cmd
      raise NodeCommandException.new "Error: #{errout} executing command #{cmd}" unless st.exitstatus == 0
    end

    def self.find_system_messages(pattern)
      regex = Regexp.new(pattern)
      open('/var/log/messages') { |f| f.grep(regex) }.join("\n")
    end

  end
end
