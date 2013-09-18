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
require 'openshift-origin-frontend-apachedb'
require 'openshift-origin-node/model/frontend/http/plugins/frontend_http_base'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'
require 'erb'
require 'json'
require 'fcntl'

$OpenShift_ApacheVirtualHosts_Lock = Mutex.new

module OpenShift
  module Runtime
    module Frontend
      module Http
        module Plugins

          class ApacheVirtualHosts < PluginBaseClass

            TEMPLATE_HTTP  = "frontend-vhost-http-template.erb"
            TEMPLATE_HTTPS = "frontend-vhost-https-template.erb"

            LOCK = $OpenShift_ApacheVirtualHosts_Lock
            LOCKFILE = "/var/run/openshift/apache-vhost.lock"

            attr_reader :basedir, :token, :app_path

            def initialize(container_uuid, fqdn, container_name, namespace)
              @config = ::OpenShift::Config.new
              @basedir = @config.get("OPENSHIFT_HTTP_CONF_DIR")

              super(container_uuid, fqdn, container_name, namespace)

              @token = "#{@container_uuid}_#{@namespace}_#{@container_name}"
              @app_path = File.join(@basedir, token)

              @template_http  = File.join(@basedir, TEMPLATE_HTTP)
              @template_https = File.join(@basedir, TEMPLATE_HTTPS)
            end


            def conf_path
              File.join(@basedir, "#{@container_uuid}_#{@namespace}_0_#{@container_name}.conf")
            end

            def element_path(path)
              if path == "*"
                tpath = "*"
                order = "5*"
              else
                tpath = path.gsub('/','_').gsub(' ','_')
                order = 599999 - [99999, path.length].min
              end
              File.join(@app_path,"#{order}_element-#{tpath}.conf")
            end

            def parse_connection(element_file)
              path, uri, options = [ "", "", {} ]
              File.open(element_file, File::RDONLY) do |f|
                f.each do |l|
                  if l =~ /^\# ELEMENT: (.*)$/
                    path, uri, options = JSON.load($~[1])
                  end
                end
              end

              if not options["protocols"]
                options["protocols"] = [ "http" ]
                if options["ssl_to_gear"]
                  options["protocols"] << "https"
                end
              end

              [ path, uri, options ]
            end

            def create
              FileUtils.mkdir_p(@app_path)
            end

            def destroy
              with_lock_and_reload do
                FileUtils.rm_rf(Dir.glob(File.join(@basedir, "#{container_uuid}_*")))
              end
            end

            def connect(*elements)
              reported_urls=[]
              with_lock_and_reload do

                # The base config won't exist until the first connection is created
                if not File.exists?(conf_path)
                  File.open(conf_path, File::RDWR | File::CREAT | File::TRUNC, 0644) do |f|
                    server_name = @fqdn
                    include_path = @app_path
                    ssl_certificate_file = '/etc/pki/tls/certs/localhost.crt'
                    ssl_key_file = '/etc/pki/tls/private/localhost.key'
                    f.write(ERB.new(File.read(@template_http)).result(binding))
                    f.write("\n")
                    f.write(ERB.new(File.read(@template_https)).result(binding))
                    f.write("\n")
                    f.fsync
                  end
                end

                # Process target_update option by loading the old values
                elements.each do |path, uri, options|

                  next if options["protocols"] and ["http", "https"].select { |proto| options["protocols"].include?(proto) }.empty?

                  if options["protocols"] and options["protocols"].include?("https") and not options["protocols"].include?("http")
                    options["ssl_to_gear"]=1
                  end

                  File.open(element_path(path), File::RDWR | File::CREAT | File::TRUNC, 0644) do |f|
                    f.write("# ELEMENT: ")
                    f.write([path, uri, options].to_json)
                    f.write("\n")

                    gen_default_rule=false
                    proxy_proto = "http"
                    if options["gone"]
                      f.puts("RewriteRule ^#{path}(/.*)?$ - [NS,G]")
                    elsif options["forbidden"]
                      f.puts("RewriteRule ^#{path}(/.*)?$ - [NS,F]")
                    elsif options["noproxy"]
                      f.puts("RewriteRule ^#{path}(/.*)?$ - [NS,L]")
                    elsif options["health"]
                      f.puts("RewriteRule ^#{path}(/.*)?$ /var/www/html/health.txt [NS,L]")
                    elsif options["redirect"]
                      f.puts("RewriteRule ^#{path}(/.*)?$ #{uri} [R,NS,L]")
                    elsif options["file"]
                      f.puts("RewriteRule ^#{path}(/.*)?$ #{uri} [NS,L]")
                    elsif options["tohttps"]
                      f.puts("RewriteCond %{HTTPS} =off")
                      f.puts("RewriteRule ^#{path}(/.*)?$ https://%{HTTP_HOST}$1 [R,NS,L]")
                      gen_default_rule = true
                    elsif options["ssl_to_gear"]
                      f.puts("RewriteCond %{HTTPS} =off")
                      f.puts("RewriteRule ^#{path}(/.*)?$ https://%{HTTP_HOST}$1 [R,NS,L]")
                      proxy_proto="https"
                      gen_default_rule = true
                    else
                      gen_default_rule = true
                    end

                    if gen_default_rule
                      f.puts("RewriteRule ^#{path}(/.*)?$ #{proxy_proto}://#{uri}$1 [P,NS]")

                      if path.empty?
                        tpath = "/"
                      else
                        tpath = path
                      end

                      if uri.empty?
                        turi = "127.0.0.1:80"
                      elsif uri.end_with?("/")
                        turi = uri
                      else
                        turi = uri + "/"
                      end

                      f.puts("ProxyPassReverse #{tpath} #{proxy_proto}://#{turi}")
                    end

                    f.fsync
                  end
                end
              end
              reported_urls
            end

            def connections
              Dir.glob(element_path('*')).map do |p|
                parse_connection(p)
              end
            end

            def disconnect(*paths)
              with_lock_and_reload do
                paths.flatten.each do |p|
                  FileUtils.rm_f(element_path(p))
                end
              end
            end



            def idle_path
              File.join(@app_path, "000000_idler.conf")
            end

            def idle
              with_lock_and_reload do
                File.open(idle_path, File::RDWR | File::CREAT | File::TRUNC, 0644 ) do |f|
                  f.puts("RewriteRule ^/(.*)$ /var/www/html/restorer.php/#{@container_uuid}/$1 [NS,L]")
                end
              end
            end

            def unidle
              with_lock_and_reload do
                FileUtils.rm_f(idle_path)
              end
            end

            def idle?
              File.exists?(idle_path)
            end



            def sts_path
              File.join(@app_path, "000001_sts_header.conf")
            end

            def sts(max_age=15768000)
              with_lock_and_reload do
                File.open(sts_path, File::RDWR | File::CREAT | File::TRUNC, 0644 ) do |f|
                  f.puts("# MAX_AGE: #{max_age.to_i}")
                  f.puts("Header set Strict-Transport-Security \"max-age=#{max_age.to_i}\"")
                  f.puts("RewriteCond %{HTTPS} =off")
                  f.puts("RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R,NS,L]")
                end
              end
            end

            def no_sts
              with_lock_and_reload do
                FileUtils.rm_f(sts_path)
              end
            end

            def get_sts
              begin
                File.read(sts_path).each_line do |l|
                  if l=~/^# MAX_AGE: (\d+)$/
                    return $~[1].to_i
                  end
                end
              rescue Errno::ENOENT
              end
              nil
            end



            def alias_path_prefix
              "888888_server_alias-"
            end

            def alias_path(server_alias)
              File.join(@app_path, "#{alias_path_prefix}#{server_alias}.conf")
            end

            def aliases
              Dir.glob(alias_path('*')).map { |f|
                File.basename(f,".conf").gsub(alias_path_prefix,'')
              } + ssl_certs.map { |ssl_cert, priv_key, server_alias|
                server_alias
              }
            end

            def add_alias_impl(server_alias)
              File.open(alias_path(server_alias), File::RDWR | File::CREAT | File::TRUNC, 0644 ) do |f|
                f.puts("ServerAlias #{server_alias}")
                f.fsync
              end
            end

            def add_alias(server_alias)
              with_lock_and_reload do
                if not File.exists?(ssl_conf_path(server_alias))
                  add_alias_impl(server_alias)
                end
              end
            end

            def remove_alias(server_alias)
              with_lock_and_reload do
                FileUtils.rm_f(alias_path(server_alias))
                remove_ssl_cert_impl(server_alias)
              end
            end



            def ssl_conf_prefix
              "#{@container_uuid}_#{@namespace}_9_"
            end

            def ssl_conf_path(server_alias)
              File.join(@basedir, ssl_conf_prefix + "#{server_alias}.conf")
            end

            def ssl_certificate_path(server_alias)
              File.join(@app_path, server_alias + ".crt")
            end

            def ssl_key_path(server_alias)
              File.join(@app_path, server_alias + ".key")
            end


            def ssl_certs
              Dir.glob(ssl_conf_path('*')).map { |conf_path|
                File.basename(conf_path, ".conf").gsub(ssl_conf_prefix, '')
              }.map { |server_alias|
                begin
                  ssl_cert = File.read(ssl_certificate_path(server_alias))
                  priv_key = File.read(ssl_key_path(server_alias))
                rescue Errno::ENOENT
                end
                [ ssl_cert, priv_key, server_alias ]
              }.select { |ssl_cert, priv_key, server_alias|
                ssl_cert.to_s != ""
              }
            end

            def add_ssl_cert(ssl_cert, priv_key, server_alias)
              with_lock_and_reload do
                if not File.exists?(alias_path(server_alias))
                  raise PluginException.new("Specified alias #{server_alias} does not exist for the app",
                                            @container_uuid, @fqdn)
                end

                ssl_certificate_file = ssl_certificate_path(server_alias)
                ssl_key_file = ssl_key_path(server_alias)

                File.open(ssl_certificate_file, File::RDWR | File::CREAT | File::TRUNC, 0644) do |f|
                  f.write(ssl_cert)
                  f.fsync
                end

                File.open(ssl_key_file, File::RDWR | File::CREAT | File::TRUNC, 0644) do |f|
                  f.write(priv_key)
                  f.fsync
                end

                File.open(ssl_conf_path(server_alias), File::RDWR | File::CREAT | File::TRUNC, 0644) do |f|
                  server_name = server_alias
                  include_path = @app_path
                  f.write(ERB.new(File.read(@template_http)).result(binding))
                  f.write("\n")
                  f.write(ERB.new(File.read(@template_https)).result(binding))
                  f.write("\n")
                  f.fsync
                end

                FileUtils.rm_f(alias_path(server_alias))
              end
            end

            def remove_ssl_cert_impl(server_alias)
              FileUtils.rm_f(ssl_conf_path(server_alias))
              FileUtils.rm_f(ssl_certificate_path(server_alias))
              FileUtils.rm_f(ssl_key_path(server_alias))
            end

            def remove_ssl_cert(server_alias)
              with_lock_and_reload do
                if File.exists?(ssl_conf_path(server_alias))
                  add_alias_impl(server_alias)
                end
                remove_ssl_cert_impl(server_alias)
              end
            end

            # Private: Lock and reload changes to Apache
            def with_lock_and_reload
              LOCK.synchronize do
                File.open(LOCKFILE, File::RDWR | File::CREAT | File::TRUNC | File::SYNC , 0640) do |f|
                  f.sync = true
                  f.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
                  f.flock(File::LOCK_EX)
                  f.write(Process.pid)
                  begin
                    yield
                  ensure
                    f.flock(File::LOCK_UN)
                  end
                end
              end
              ::OpenShift::Runtime::Frontend::Http::Plugins::reload_httpd
            end

          end

        end
      end
    end
  end
end
