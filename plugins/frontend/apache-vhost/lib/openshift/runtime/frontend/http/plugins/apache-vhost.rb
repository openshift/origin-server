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
require 'openshift-origin-common'
require 'openshift-origin-node/model/frontend/http/plugins/frontend_http_base'
require 'openshift-origin-node/utils/shell_exec'
require 'openshift-origin-node/utils/node_logger'
require 'erb'
require 'json'
require 'fcntl'

module OpenShift
  module Runtime
    module Frontend
      module Http
        module Plugins

          class ApacheVirtualHosts < PluginBaseClass

            TEMPLATE_HTTP  = 'frontend-vhost-http-template.erb'
            TEMPLATE_HTTPS = 'frontend-vhost-https-template.erb'
            LOCKFILE       = '/var/run/openshift/apache-vhost.lock'

            FILE_OPTS = File::RDWR | File::CREAT | File::TRUNC | File::SYNC

            attr_reader :basedir, :token, :app_path

            def initialize(container_uuid, fqdn, container_name, namespace, application_uuid=nil)
              @config = ::OpenShift::Config.new
              @basedir = @config.get("OPENSHIFT_HTTP_CONF_DIR")

              super(container_uuid, fqdn, container_name, namespace, application_uuid)

              @token = "#{@container_uuid}_#{@namespace}_#{@container_name}"
              @app_path = PathUtils.join(@basedir, token)

              @template_http  = PathUtils.join(@basedir, TEMPLATE_HTTP)
              @template_https = PathUtils.join(@basedir, TEMPLATE_HTTPS)
              @ssl_cert_path = (@config.get("OPENSHIFT_DEFAULT_SSL_CRT_PATH") || "/etc/pki/tls/certs/localhost.crt")
              @ssl_chain_path = (@config.get("OPENSHIFT_DEFAULT_SSL_CRT_CHAIN_PATH") || "/etc/pki/tls/certs/localhost.crt")
              @ssl_key_path = (@config.get("OPENSHIFT_DEFAULT_SSL_KEY_PATH") || "/etc/pki/tls/private/localhost.key")
            end


            def conf_path
              PathUtils.join(@basedir, "#{@container_uuid}_#{@namespace}_0_#{@container_name}.conf")
            end

            def ha_conf_path
              PathUtils.join(@basedir, "#{@container_uuid}_#{@namespace}_0_#{@container_name}_ha.conf")
            end

            def element_path(path)
              if path == "*"
                tpath = "*"
                order = "5*"
              else
                tpath = path.gsub('/','_').gsub(' ','_')
                order = 599999 - [99999, path.length].min
              end
              PathUtils.join(@app_path,"#{order}_element-#{tpath}.conf")
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

            def self.purge_by_uuid(uuid)
              basedir = ::OpenShift::Config.new.get('OPENSHIFT_HTTP_CONF_DIR')
              with_lock_and_reload do
                truncate(PathUtils.join(basedir, "#{uuid}_*"))
              end
            end

            def self.purge_by_fqdn(fqdn)
              # Determine the UUID so that we can catch aliases.
              basedir = ::OpenShift::Config.new.get('OPENSHIFT_HTTP_CONF_DIR')
              name = fqdn.sub(/\..*$/,'')
              Dir.glob(PathUtils.join(basedir, "*_#{name}.conf")).map { |p|
                File.basename(p).sub(/_.*$/,'')
              }.each do |uuid|
                purge_by_uuid(uuid)
              end
            end

            def destroy
              with_lock_and_reload do
                truncate(PathUtils.join(@basedir, "#{@container_uuid}_*"))
              end
            end

            def write_base_config(file_name)
              File.open(file_name, FILE_OPTS, 0644) do |f|
                # setup binding environment
                server_name                = @fqdn
                include_path               = @app_path
                app_uuid                   = @application_uuid
                gear_uuid                  = @container_uuid
                app_namespace              = @namespace
                ssl_certificate_file       = @ssl_cert_path
                ssl_certificate_chain_file = @ssl_chain_path
                ssl_key_file               = @ssl_key_path

                buffer = ERB.new(File.read(@template_http)).result(binding) << "\n"
                buffer << ERB.new(File.read(@template_https)).result(binding) << "\n"
                f.write(buffer)
              end
            end

            def connect(*elements)
              with_lock_and_reload do

                raise PluginException.new("Base directory #{@app_path} does not exist for the app",
                                          @container_uuid, @fqdn) if not Dir.exists?(@app_path)

                # The base config won't exist until the first connection is created
                unless File.size?(conf_path)
                  write_base_config(conf_path)
                end

                # Secondary haproxy gear: if the @fqdn is the app dns, then it won't start with
                # @container_name (as that should be the gear's uuid). If the ha conf file
                # doesn't exist, create it
                if !@fqdn.start_with?(@container_name.downcase) and !File.size?(ha_conf_path)
                  write_base_config(ha_conf_path)
                end

                # Process target_update option by loading the old values
                elements.each do |path, uri, options|

                  next if options["protocols"] and ["http", "https"].select { |proto| options["protocols"].include?(proto) }.empty?

                  if options["protocols"] and options["protocols"].include?("https") and not options["protocols"].include?("http")
                    options["ssl_to_gear"]=1
                  end

                  buffer = '# ELEMENT: ' << [path, uri, options].to_json << "\n"

                  gen_default_rule=false
                  proxy_proto     = 'http'
                  if options['gone']
                    buffer << "RewriteRule ^#{path}(/.*)?$ - [NS,G]\n"
                  elsif options['forbidden']
                    buffer << "RewriteRule ^#{path}(/.*)?$ - [NS,F]\n"
                  elsif options['noproxy']
                    buffer << "RewriteRule ^#{path}(/.*)?$ - [NS,L]\n"
                  elsif options['health']
                    buffer << "RewriteRule ^#{path}(/.*)?$ /var/www/html/health.txt [NS,L]\n"
                  elsif options['redirect']
                    buffer << "RewriteRule ^#{path}(/.*)?$ #{uri} [R,NS,L]\n"
                  elsif options['file']
                    buffer << "RewriteRule ^#{path}(/.*)?$ #{uri} [NS,L]\n"
                  elsif options['tohttps']
                    buffer << "RewriteCond %{HTTPS} =off\n"
                    buffer << "RewriteRule ^#{path}(/.*)?$ https://%{HTTP_HOST}$1 [R,NS,L]\n"
                    gen_default_rule = true
                  elsif options['ssl_to_gear']
                    buffer << "RewriteCond %{HTTPS} =off\n"
                    buffer << "RewriteRule ^#{path}(/.*)?$ https://%{HTTP_HOST}$1 [R,NS,L]\n"
                    proxy_proto      ="https"
                    gen_default_rule = true
                  else
                    gen_default_rule = true
                  end

                  if gen_default_rule
                    tpath = path.empty? ? "/" : path

                    if uri.empty?
                      turi = "127.0.0.1:80"
                    elsif tpath[-1] != uri[-1]
                      # tpath and uri are unequal, fix uri to match tpath
                      if uri.end_with?("/")
                        turi = uri[0..-2]
                      else
                        turi = uri + "/"
                      end
                    else
                      turi = uri
                    end

                    buffer << "ProxyPass #{tpath} #{proxy_proto}://#{turi} retry=0\n"
                    buffer << "ProxyPassReverse #{tpath} #{proxy_proto}://#{turi}\n"
                    buffer << "ProxyPassReverse #{tpath} #{proxy_proto}://#{fqdn}#{tpath}\n"
                  end

                  File.open(element_path(path), FILE_OPTS, 0644) do |file|
                    file.write(buffer)
                  end
                end
              end

              []
            end

            def connections
              candidates = Dir.glob(element_path('*'))
              candidates.delete_if { |f| not File.size?(f)}
              candidates.map do |p|
                parse_connection(p)
              end
            end

            def disconnect(*paths)
              with_lock_and_reload do
                paths.flatten.each do |p|
                  truncate(element_path(p))
                end
              end
            end

            def idle_path
              PathUtils.join(@app_path, "000000_idler.conf")
            end

            def idle
              with_lock_and_reload do
                File.open(idle_path, FILE_OPTS, 0644 ) do |f|
                  f.write("RewriteRule ^/(.*)$ /var/www/html/restorer.php/#{@container_uuid}/$1 [NS,L]\n")
                end
              end
            end

            def unidle
              with_lock_and_reload do
                truncate(idle_path)
              end
            end

            def idle?
              !! File.size?(idle_path)
            end

            def sts_path
              PathUtils.join(@app_path, "000001_sts_header.conf")
            end

            def sts(max_age=15768000)
              with_lock_and_reload do
                File.open(sts_path, FILE_OPTS, 0644 ) do |f|
                  buffer = %Q(# MAX_AGE: #{max_age.to_i}\n)
                  buffer << %Q(Header set Strict-Transport-Security "max-age=#{max_age.to_i}"\n)
                  buffer << %Q(RewriteCond %{HTTPS} =off\n)
                  buffer << %Q(RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R,NS,L]\n)
                  f.write(buffer)
                end
              end
            end

            def no_sts
              with_lock_and_reload do
                truncate(sts_path)
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
              PathUtils.join(@app_path, "#{alias_path_prefix}#{server_alias}.conf")
            end

            def aliases
              candidates = Dir.glob(alias_path('*'))
              candidates.delete_if { |f| not File.size?(f) }
              candidates.map do |f|
                File.basename(f, '.conf').gsub(alias_path_prefix, '')
              end + ssl_certs.map { |_, _, server_alias| server_alias }
            end

            def add_alias_impl(server_alias)
              File.open(alias_path(server_alias), FILE_OPTS, 0644) do |f|
                buffer = "ServerAlias #{server_alias}\n"
                buffer << "ProxyPassReverse / http://#{server_alias}/\n"
                f.write(buffer)
              end
            end

            def add_alias(server_alias)
              add_aliases([server_alias])
            end

            def add_aliases(server_aliases)
              with_lock_and_reload do
                server_aliases.each do |server_alias|
                  unless File.size?(ssl_conf_path(server_alias))
                    add_alias_impl(server_alias)
                  end
                end
              end
            end

            def remove_alias(server_alias)
              remove_aliases([server_alias])
            end

            def remove_aliases(server_aliases)
              with_lock_and_reload do
                server_aliases.each do |server_alias|
                  truncate(alias_path(server_alias))
                  remove_ssl_cert_impl(server_alias)
                end
              end
            end

            def ssl_conf_prefix
              "#{@container_uuid}_#{@namespace}_9_"
            end

            def ssl_conf_path(server_alias)
              PathUtils.join(@basedir, ssl_conf_prefix + "#{server_alias}.conf")
            end

            def ssl_certificate_path(server_alias)
              PathUtils.join(@app_path, server_alias + ".crt")
            end

            def ssl_key_path(server_alias)
              PathUtils.join(@app_path, server_alias + ".key")
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
                                            @container_uuid, @fqdn
                    # BZ 1090358 in the case of reconstructing the frontend for a moved gear,
                    # the alias_path is already removed in favor of the vhost ssl_conf_path,
                    # so just proceed if that is already there:
                                           ) unless File.size?(ssl_conf_path(server_alias))
                end

                ssl_certificate_file = ssl_certificate_path(server_alias)
                ssl_key_file = ssl_key_path(server_alias)
                ssl_certificate_chain_file = ssl_certificate_path(server_alias)

                File.open(ssl_certificate_file, FILE_OPTS, 0600) do |f|
                  f.write(ssl_cert)
                end

                File.open(ssl_key_file, FILE_OPTS, 0600) do |f|
                  f.write(priv_key)
                end

                File.open(ssl_conf_path(server_alias), FILE_OPTS, 0644) do |f|
                  # setup binding environment for ERB processing
                  server_name = server_alias
                  include_path = @app_path
                  app_uuid = @application_uuid
                  gear_uuid = @container_uuid
                  app_namespace = @namespace

                  buffer = ERB.new(File.read(@template_http)).result(binding)  << "\n"
                  buffer << ERB.new(File.read(@template_https)).result(binding) << "\n"
                  f.write(buffer)
                end

                truncate(alias_path(server_alias))
              end
            end

            def remove_ssl_cert_impl(server_alias)
              truncate(ssl_conf_path(server_alias))
              truncate(ssl_certificate_path(server_alias))
              truncate(ssl_key_path(server_alias))
              truncate(ssl_key_path(server_alias))
            end

            def remove_ssl_cert(server_alias)
              with_lock_and_reload do
                if File.size?(ssl_conf_path(server_alias))
                  add_alias_impl(server_alias)
                end
                remove_ssl_cert_impl(server_alias)
              end
            end

            # Private: Lock and reload changes to Apache
            def self.with_lock_and_reload
              PathUtils.flock(LOCKFILE, false) { yield }
              ::OpenShift::Runtime::Frontend::Http::Plugins::reload_httpd
            end

            def with_lock_and_reload(&block)
              self.class.with_lock_and_reload(&block)
            end

            def self.truncate(path)
              Dir.glob(path).each { |e| File.truncate(e, 0) if File.file?(e) }
            end

            def truncate(path)
              self.class.truncate(path)
            end
          end

        end
      end
    end
  end
end
