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
require 'openshift-origin-frontend-apachedb'
require 'openshift-origin-node/model/frontend/http/plugins/frontend_http_base'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'
require 'erb'

$OpenShift_ApacheDBNodes_Lock = Mutex.new
$OpenShift_ApacheDBAliases_Lock = Mutex.new
$OpenShift_ApacheDBIdler_Lock = Mutex.new
$OpenShift_ApacheDBSTS_Lock = Mutex.new

module OpenShift
  module Runtime
    module Frontend
      module Http
        module Plugins

          class ApacheModRewrite < PluginBaseClass

            TEMPLATE_HTTPS = "frontend-mod-rewrite-https-template.erb"

            def initialize(container_uuid, fqdn, container_name, namespace, application_uuid=nil)
              @config = ::OpenShift::Config.new
              @basedir = @config.get("OPENSHIFT_HTTP_CONF_DIR")

              super(container_uuid, fqdn, container_name, namespace, application_uuid)

              @template_https = File.join(@basedir, TEMPLATE_HTTPS)
            end

            def self.purge_by_fqdn(fqdn)
              ApacheDBNodes.open(ApacheDBNodes::WRCREAT)     { |d| d.delete_if { |k, v| k.split('/')[0] == fqdn } }
              ApacheDBAliases.open(ApacheDBAliases::WRCREAT) { |d| d.delete_if { |k, v| v == fqdn } }
              ApacheDBIdler.open(ApacheDBIdler::WRCREAT)     { |d| d.delete(fqdn) }
              ApacheDBSTS.open(ApacheDBSTS::WRCREAT)         { |d| d.delete(fqdn) }
            end

            def self.purge_by_uuid(uuid)
              # Clean up SSL certs and legacy node configuration
              basedir = ::OpenShift::Config.new.get("OPENSHIFT_HTTP_CONF_DIR")
              ApacheDBAliases.open(ApacheDBAliases::WRCREAT) do
                paths = Dir.glob(PathUtils.join(basedir, "#{uuid}_*"))
                FileUtils.rm_rf(paths)
                paths.each do |p|
                  if p =~ /\.conf$/
                    begin
                      ::OpenShift::Runtime::Frontend::Http::Plugins::reload_httpd
                    rescue
                    end
                    break
                  end
                end
              end
            end

            def destroy
              self.class.purge_by_fqdn(@fqdn)
              self.class.purge_by_uuid(@container_uuid)
            end

            def connect(*elements)
              reported_urls = []
              ApacheDBNodes.open(ApacheDBNodes::WRCREAT) do |d|
                elements.each do |path, uri, options|

                  next if options["protocols"] and ["http", "https"].select { |proto| options["protocols"].include?(proto) }.empty?

                  if options["protocols"] and options["protocols"].include?("https") and not options["protocols"].include?("http")
                    options["ssl_to_gear"]=1
                  end

                  if options["gone"]
                    map_dest = "GONE"
                  elsif options["forbidden"]
                    map_dest = "FORBIDDEN"
                  elsif options["noproxy"]
                    map_dest = "NOPROXY"
                  elsif options["health"]
                    map_dest = "HEALTH"
                  elsif options["redirect"]
                    map_dest = "REDIRECT:#{uri}"
                  elsif options["file"]
                    map_dest = "FILE:#{uri}"
                  elsif options["ssl_to_gear"]
                    map_dest = "SSL_TO_GEAR:#{uri}"
                  elsif options["tohttps"]
                    map_dest = "TOHTTPS:#{uri}"
                  else
                    map_dest = uri
                  end

                  # include the app uuid and gear uuid so we can add them to the
                  # apache access log if needed
                  map_dest += "|#{@application_uuid}|#{@container_uuid}"

                  d.store(@fqdn + path.to_s, map_dest)
                end
              end
              reported_urls
            end


            def decode_connection(path, connection)
              entry = [ path, "", {} ]

              entry[2]["protocols"]=[ "http" ]

              if connection =~ /^(GONE|FORBIDDEN|NOPROXY|HEALTH)/
                entry[2][$~[1].downcase] = 1
              elsif connection =~ /^(REDIRECT|FILE|TOHTTPS|SSL_TO_GEAR):(.*)$/
                entry[2][$~[1].downcase] = 1
                entry[1] = $~[2].split("|").first
              else
                entry[1] = connection.split("|").first
              end

              if entry[2]["ssl_to_gear"]
                entry[2]["protocols"] << "https"
              end

              entry
            end


            def connections
              # We can't simply rely on the open returning the block's value in unit testing.
              # http://rubyforge.org/tracker/?func=detail&atid=7477&aid=8687&group_id=1917
              entries = nil
              ApacheDBNodes.open(ApacheDBNodes::READER) do |d|
                entries = d.select { |k, v|
                  k.split('/')[0] == @fqdn
                }.map { |k, v|
                  decode_connection(k.sub(@fqdn, ""), v)
                }
              end
              entries

            end


            def disconnect(*paths)
              ApacheDBNodes.open(ApacheDBNodes::WRCREAT) do |d|
                paths.flatten.each do |p|
                  d.delete(@fqdn + p.to_s)
                end
              end
            end

            def idle
              ApacheDBIdler.open(ApacheDBIdler::WRCREAT) do |d|
                d.store(@fqdn, @container_uuid)
              end
            end

            def unidle
              ApacheDBIdler.open(ApacheDBIdler::WRCREAT) do |d|
                d.delete(@fqdn)
              end
            end

            def idle?
              ApacheDBIdler.open(ApacheDBIdler::READER) do |d|
                return d.has_key?(@fqdn)
              end
            end

            def sts(max_age=15768000)
              ApacheDBSTS.open(ApacheDBSTS::WRCREAT) do |d|
                if max_age.nil?
                  d.delete(@fqdn)
                else
                  d.store(@fqdn, max_age.to_i)
                end
              end
            end

            def no_sts
              ApacheDBSTS.open(ApacheDBSTS::WRCREAT) do |d|
                d.delete(@fqdn)
              end
            end

            def get_sts
              ApacheDBSTS.open(ApacheDBSTS::READER) do |d|
                if d.has_key?(@fqdn)
                  return d.fetch(@fqdn)
                end
              end
              nil
            end

            def aliases
              ApacheDBAliases.open(ApacheDBAliases::READER) do |d|
                return d.select { |k, v| v == @fqdn }.map { |k, v| k }
              end
            end

            def add_alias(name)
              add_aliases([name])
            end

            def add_aliases(names)
              # Broker checks for global uniqueness
              ApacheDBAliases.open(ApacheDBAliases::WRCREAT) do |d|
                names.each do |name|
                  d.store(name, @fqdn)
                end
              end
            end

            def remove_alias(name)
              remove_aliases([name])
            end

            def remove_aliases(names)
              ApacheDBAliases.open(ApacheDBAliases::WRCREAT) do |d|
                names.each do |name|
                  d.delete(name)
                end
              end
              names.each do |name|
                remove_ssl_cert(name)
              end
            end


            def ssl_certs
              aliases.map { |a|
                alias_token = "#{@container_uuid}_#{@namespace}_#{a}"
                alias_conf_dir_path = PathUtils.join(@basedir, alias_token)
                ssl_cert_file_path = PathUtils.join(alias_conf_dir_path, a + ".crt")
                priv_key_file_path = PathUtils.join(alias_conf_dir_path, a + ".key")

                begin
                  ssl_cert = File.read(ssl_cert_file_path).chomp
                  priv_key = File.read(priv_key_file_path).chomp
                rescue
                  ssl_cert = nil
                  priv_key = nil
                end

                [ ssl_cert, priv_key, a ]
              }.select { |e| e[0] != nil }
            end


            def add_ssl_cert(ssl_cert, priv_key, server_alias)
              # Create a new directory for the alias and copy the certificates
              alias_token = "#{@container_uuid}_#{@namespace}_#{server_alias}"
              alias_conf_dir_path = PathUtils.join(@basedir, alias_token)
              ssl_certificate_file = PathUtils.join(alias_conf_dir_path, server_alias + ".crt")
              ssl_key_file = PathUtils.join(alias_conf_dir_path, server_alias + ".key")

              #
              # Create configuration for the alias
              #

              # Finally, commit the changes
              ApacheDBAliases.open(ApacheDBAliases::WRCREAT) do |d|
                if not (d.has_key? server_alias)
                  raise PluginException.new("Specified alias #{server_alias} does not exist for the app",
                                            @container_uuid, @fqdn)
                end

                FileUtils.mkdir_p(alias_conf_dir_path)

                File.open(ssl_certificate_file, File::RDWR | File::CREAT | File::TRUNC, 0600) do |f|
                  f.puts(ssl_cert)
                  f.fsync
                end

                File.open(ssl_key_file, File::RDWR | File::CREAT | File::TRUNC, 0600) do |f|
                  f.puts(priv_key)
                  f.fsync
                end

                alias_conf_file_path = PathUtils.join(@basedir, "#{alias_token}.conf")
                File.open(alias_conf_file_path, File::RDWR | File::CREAT | File::TRUNC, 0644) do |f|
                  server_name = server_alias
                  f.puts(ERB.new(File.read(@template_https)).result(binding))
                  f.fsync
                end

                # Reload httpd to pick up the new configuration
                ::OpenShift::Runtime::Frontend::Http::Plugins::reload_httpd
              end
            end

            def remove_ssl_cert(server_alias)
              #
              # Remove the alias specific configuration
              #
              alias_token = "#{@container_uuid}_#{@namespace}_#{server_alias}"

              alias_conf_dir_path = PathUtils.join(@basedir, alias_token)
              alias_conf_file_path = PathUtils.join(@basedir, "#{alias_token}.conf")

              if File.exists?(alias_conf_file_path) or File.exists?(alias_conf_dir_path)
                ApacheDBAliases.open(ApacheDBAliases::WRCREAT) do

                  FileUtils.rm_rf(alias_conf_file_path)
                  FileUtils.rm_rf(alias_conf_dir_path)

                  # Reload httpd to pick up the configuration changes
                  ::OpenShift::Runtime::Frontend::Http::Plugins::reload_httpd
                end
              end
            end

          end

          class ApacheDBNodes < ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheDB
            self.MAPNAME = "nodes"
            self.LOCK = $OpenShift_ApacheDBNodes_Lock
          end

          class ApacheDBAliases < ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheDB
            self.MAPNAME = "aliases"
            self.LOCK = $OpenShift_ApacheDBAliases_Lock
          end

          class ApacheDBIdler < ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheDB
            self.MAPNAME = "idler"
            self.LOCK = $OpenShift_ApacheDBIdler_Lock
          end

          class ApacheDBSTS < ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheDB
            self.MAPNAME = "sts"
            self.LOCK = $OpenShift_ApacheDBSTS_Lock
          end

        end
      end
    end
  end
end
