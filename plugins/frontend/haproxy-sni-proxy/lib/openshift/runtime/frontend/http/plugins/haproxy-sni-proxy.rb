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
require 'openshift-origin-common/config'

require 'erb'

$OpenShift_HaproxySNIProxyDB_Lock = Mutex.new

module OpenShift
  module Runtime
    module Frontend
      module Http
        module Plugins

          class HaproxySNIProxy < PluginBaseClass

            attr_reader :sni_ports

            def initialize(*args)
              @sni_ports = HaproxySNIProxyDB.get_ports

              super(*args)
            end

            def create
              with_create
            end

            def self.purge_by_fqdn(fqdn)
              HaproxySNIProxyDB.open(HaproxySNIProxyDB::WRCREAT) do |d|
                d.delete(fqdn)
              end
            end

            def destroy
              writer_if_exists do |d|
                d.delete(@fqdn)
              end
            end


            def connect(*elements)
              reported_urls=[]
              with_create do |d|
                elements.each do |path, uri, options|

                  next unless options["protocols"] and options["protocols"].include?("tls")

                  if path.empty?
                    reqport = @sni_ports[0]
                  elsif path =~ /^TLS_PORT_(\d+)$/
                    idx = $~[1].to_i - 1
                    if idx >=0
                      reqport = @sni_ports[idx]
                    end
                  elsif @sni_ports.include?(path.to_i)
                    reqport = path.to_i
                  end

                  if not reqport
                    raise PluginException.new("Invalid port specified for SNI proxy \"#{path}\" (must either be \"\", or TLS_PORT_1, TLS_PORT_2, etc...)", @container_uuid, @fqdn)
                  end

                  if uri !~ /^\d+\.\d+\.\d+\.\d+\:\d+$/
                    raise PluginException.new("SNI proxy target must be IP:PORT", @container_uuid, @fqdn)
                  end

                  d[@fqdn]["connections"][reqport]=uri

                  reported_urls << "tls:#{@fqdn}:#{reqport}"

                end
              end
              reported_urls
            end

            def connections
              reader_if_exists do |d|
                return d[@fqdn]["connections"].select { |port, backend|
                  backend.to_s != ""
                }.map { |port, backend|
                  ["TLS_PORT_#{@sni_ports.index(port.to_i).to_i+1}", backend, { "protocols"=>["tls"] } ]
                }
              end
              []
            end

            def disconnect(*paths)
              writer_if_exists do |d|
                paths.each do |path|
                  reqport = path
                  if path=~/^TLS_PORT_(\d+)$/
                    idx = $~[1].to_i - 1
                    if idx >=0
                      reqport = @sni_ports[idx]
                    end
                  end
                  d[@fqdn]["connections"].delete(reqport)
                end
              end
            end

            def aliases
              reader_if_exists do |d|
                return d[@fqdn]["aliases"].clone
              end
              nil
            end

            def add_alias(name)
              add_aliases([name])
            end

            def add_aliases(names)
              with_create do |d|
                d[@fqdn]["aliases"].push(*names)
              end
            end

            def remove_alias(name)
              remove_aliases([name])
            end

            def remove_aliases(names)
              writer_if_exists do |d|
                names.each do |name|
                  d[@fqdn]["aliases"].delete(name)
                end
              end
            end


            private

            # Private: Create the database entry if it does not already exist.
            def with_create
              HaproxySNIProxyDB.open(HaproxySNIProxyDB::WRCREAT) do |d|
                if not d.has_key?(@fqdn)
                  d[@fqdn]={
                    "aliases" => [],
                    "connections" => {}
                  }
                end
                if block_given?
                  yield(d)
                end
              end
            end

            # Private: Yield the provided block if the record exists
            def reader_if_exists
              HaproxySNIProxyDB.open(HaproxySNIProxyDB::READER) do |d|
                if block_given? and d.has_key?(@fqdn)
                  yield(d)
                end
              end
            end

            # Private: Yield the provided block if the record exists
            # and allow modifications.
            def writer_if_exists
              HaproxySNIProxyDB.open(HaproxySNIProxyDB::WRCREAT) do |d|
                if block_given? and d.has_key?(@fqdn)
                  yield(d)
                end
              end
            end

          end

          #
          # SNI Proxy Database
          #
          # Structure:
          # fqdn => {
          #    aliases => [ alias1, alias2, alias3, ... ]
          #    connections => {
          #        port1 => backend 1
          #        port2 => backend 2
          #        port3 => backend 3
          #    }
          # }
          #
          class HaproxySNIProxyDB < ::OpenShift::Runtime::Frontend::Http::Plugins::ApacheDBJSON
            self.MAPNAME = "sniproxy"
            self.LOCK = $OpenShift_HaproxySNIProxyDB_Lock

            DEFAULT_SNI_PROXY_PORTS = "2303,2304,2305,2306,2307,2308"
            CONFIG_PATH = "/etc/openshift/node-plugins.d/openshift-origin-frontend-haproxy-sni-proxy.conf"

            def self.get_ports
              (::OpenShift::Config.new(CONFIG_PATH).get("PROXY_PORTS") or DEFAULT_SNI_PROXY_PORTS).split(",").map { |p| p.to_i }
            end

            def callout
              begin
                cfg_template     = ERB.new(File.read(@filename + "-cfg.erb"))
                listen_template  = ERB.new(File.read(@filename + "-listen.erb"))
                sni_template     = ERB.new(File.read(@filename + "-sni.erb"))
                server_template  = ERB.new(File.read(@filename + "-server.erb"))


                proxy_cfg = ::OpenShift::Config.new(CONFIG_PATH)

                # Go through contortions to bind to just the external IP address.
                # This can be obtained in the following ways:
                # 1. The BIND_IP setting in our own module configuration.
                # 2. Reading the first IP address off of EXTERNAL_ETH_DEV
                # 3. The route that points to PUBLIC_IP (on some clouds, PUBLIC_IP isn't local).
                # 4. If all of those fail, bind to any addr
                bind_ip = (proxy_cfg.get("BIND_IP") or "")

                if bind_ip == ""
                  config    = ::OpenShift::Config.new
                  test_iface = config.get("EXTERNAL_ETH_DEV")
                  test_public = config.get("PUBLIC_IP")

                  if test_iface
                    out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("ip -o -4 addr show dev #{test_iface}")
                    if out=~/inet (\d+\.\d+\.\d+\.\d+)/
                      bind_ip=$1
                    end
                  elsif test_public
                    out, err, rc = ::OpenShift::Runtime::Utils::oo_spawn("ip -o -4 route get #{test_public}")
                    if out=~/src (\d+\.\d+\.\d+\.\d+)/
                      bind_ip=$1
                    end
                  end
                end

                ports = (proxy_cfg.get("PROXY_PORTS") or DEFAULT_SNI_PROXY_PORTS).split(",").map { |p| p.to_i }
                haproxy_user = (proxy_cfg.get("HAPROXY_USER") or "haproxy")
                haproxy_run_path = (proxy_cfg.get("HAPROXY_RUN_PATH") or "/var/lib/haproxy")

                File.open(@filename + ".cfg" + "-", File::RDWR | File::CREAT | File::TRUNC, 0640) do |f|
                  f.write(cfg_template.result(binding))

                  ports.each do |port|
                    bind_addrs=[]
                    if (bind_ip != "") and (bind_ip!="127.0.0.1")
                      bind_addrs << "127.0.0.1:#{port}"
                    end
                    bind_addrs << "#{bind_ip}:#{port}"

                    f.write(listen_template.result(binding))
                    self.each do |fqdn, entry|
                      entry["connections"].select { |p, b| p.to_i == port }.each do |p, backend|
                        sni_name = fqdn
                        f.write(sni_template.result(binding))
                        entry["aliases"].each do |sni_name|
                          f.write(sni_template.result(binding))
                        end
                        f.write(server_template.result(binding))
                      end
                    end
                  end

                  f.fsync
                end

                oldstat = File.stat(@filename + ".cfg")
                File.chown(oldstat.uid, oldstat.gid, @filename + ".cfg" + "-")
                File.chmod(oldstat.mode & 0777, @filename + ".cfg" + "-")
                FileUtils.mv(@filename + ".cfg" + "-", @filename + ".cfg", :force=>true)

                cmd = %{/sbin/service openshift-sni-proxy condreload}
                ::OpenShift::Runtime::Utils::oo_spawn(cmd, :expected_exitstatus=> 0)
              rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
                NodeLogger.logger.error("ERROR: failed to reload SNI proxy: #{e.rc}: stdout: #{e.stdout} stderr:#{e.stderr}")
              rescue => e
                NodeLogger.logger.error("ERROR: processing SNI proxy: #{e.message}")
              end
            end
          end

        end
      end
    end
  end
end
