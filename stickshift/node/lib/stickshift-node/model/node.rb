#!/usr/bin/env ruby
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

require 'stickshift-node'
require 'stickshift-common'

module StickShift
  class Node < Model
    def self.get_cartridge_list(list_descriptors = false, porcelain = false, ss_debug = false)
      carts = []

      cartridge_path = StickShift::Config.instance.get("CARTRIDGE_BASE_PATH")
      Dir.foreach(cartridge_path) do |cart_dir|
        next if [".", "..", "embedded", "abstract", "abstract-httpd", "haproxy-1.4", "mysql-5.1"].include? cart_dir
        path = File.join(cartridge_path, cart_dir, "info", "manifest.yml")
        begin
          print "Loading #{cart_dir}..." if ss_debug
          carts.push StickShift::Cartridge.new.from_descriptor(YAML.load(File.open(path)))
          print "OK\n" if ss_debug
        rescue Exception => e
          print "ERROR\n" if ss_debug
          print "#{e.message}\n#{e.backtrace.inspect}\n" unless porcelain
        end
      end

      embedded_cartridge_path = File.join(cartridge_path, "embedded")
      if File.directory?(embedded_cartridge_path)
        Dir.foreach(embedded_cartridge_path) do |cart_dir|
          next if [".",".."].include? cart_dir
          path = File.join(embedded_cartridge_path, cart_dir, "info", "manifest.yml")
          begin
            print "Loading #{cart_dir}..." if ss_debug
            carts.push StickShift::Cartridge.new.from_descriptor(YAML.load(File.open(path)))
            print "OK\n" if ss_debug
          rescue Exception => e
            print "ERROR\n" if ss_debug
            print "#{e.message}\n#{e.backtrace.inspect}\n" unless porcelain
          end
        end
      end

      print "\n\n\n" if ss_debug

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

    def self.get_cartridge_info(cart_name, porcelain = false, ss_debug = false)
      output = ""
      cart_found = false

      cartridge_path = StickShift::Config.instance.get("CARTRIDGE_BASE_PATH")
      Dir.foreach(cartridge_path) do |cart_dir|
        next if [".", "..", "embedded", "abstract", "abstract-httpd", "mysql-5.1"].include? cart_dir
        path = File.join(cartridge_path, cart_dir, "info", "manifest.yml")
        begin
          cart = StickShift::Cartridge.new.from_descriptor(YAML.load(File.open(path)))
          if cart.name == cart_name
            output << "CLIENT RESULT: "
            output << cart.to_descriptor.to_json
            cart_found = true
            break
          end
        rescue Exception => e
          print "ERROR\n" if ss_debug
          print "#{e.message}\n#{e.backtrace.inspect}\n" unless porcelain
        end
      end

      embedded_cartridge_path = File.join(cartridge_path, "embedded")
      if (! cart_found) and File.directory?(embedded_cartridge_path)
        Dir.foreach(embedded_cartridge_path) do |cart_dir|
          next if [".",".."].include? cart_dir
          path = File.join(embedded_cartridge_path, cart_dir, "info", "manifest.yml")
          begin
            cart = StickShift::Cartridge.new.from_descriptor(YAML.load(File.open(path)))
            if cart.name == cart_name
              output << "CLIENT RESULT: "
              output << cart.to_descriptor.to_json
              break
            end
          rescue Exception => e
            print "ERROR\n" if ss_debug
            print "#{e.message}\n#{e.backtrace.inspect}\n" unless porcelain
          end
        end
      end
      output
    end
  end
end

