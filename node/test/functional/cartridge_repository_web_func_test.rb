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
require_relative '../test_helper'
require 'webrick'
require 'webrick/https'
require 'thread'
require 'openssl'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-node/model/cartridge_repository'
require 'openshift-origin-common/models/manifest'
require 'digest'
require 'webmock'
require 'webmock/minitest'

class CartridgeRepositoryWebFunctionalTest < OpenShift::V2SdkTestCase
  include WEBrick

  def before_setup
    @uuid = %x(uuidgen -r |sed -e s/-//g).chomp
    @port = 6001

    @test_home   = "/tmp/tests/#{@uuid}"
    @doc_root    = "#{@test_home}/www"
    @config_home = "#{@test_home}/config"

    @tgz_file = File.join(@doc_root, 'mock_plugin.tar.gz')

    FileUtils.mkdir_p(@doc_root)
    FileUtils.mkdir_p(@config_home)
    assert_path_exist @test_home

    cr = OpenShift::CartridgeRepository.instance
    cr.load
    @cartridge = cr.select('mock-plugin', '0.1')
    puts %x(shopt -s dotglob;
         cd #{@cartridge.repository_path};
         tar zcf #{@tgz_file} ./*;
      )
    @tgz_hash = %x(md5sum #{@tgz_file} |cut -d' ' -f1)

    @manifest = IO.read(File.join(@cartridge.manifest_path))

  end

  def after_teardown
    FileUtils.rm_rf @test_home
  end

  def setup
    WebMock.allow_net_connect!

    private_file = File.join(@config_home, 'private_key.pem')
    %x(/usr/bin/openssl genrsa -out #{private_file} 2048 2>&1)

    certificate_file = File.join(@config_home, 'certificate.pem')
    %x(openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout #{private_file}  -out #{certificate_file} 2>&1)

    key  = OpenSSL::PKey::RSA.new(IO.read(private_file))
    cert = OpenSSL::X509::Certificate.new(IO.read(certificate_file))

    @config = {
        Port:                @port,
        BindAddress:         'localhost',
        DocumentRoot:        @doc_root,
        DocumentRootOptions: {FancyIndexing: true},
        SSLEnable:           true,
        SSLVerifyClient:     OpenSSL::SSL::VERIFY_NONE,
        SSLPrivateKey:       key,
        SSLCertificate:      cert,
        SSLCertName:         [['CN', 'www.example.com']]
    }

    @web_thread = Thread.new do
      @server = HTTPServer.new(@config)
      %w(INT TERM).each { |signal|
        trap(signal) { @server.shutdown }
      }

      @server.start
    end
    sleep 2

  end

  def teardown
    Thread.kill(@web_thread)
  end

  def test_https_get
    manifest = @manifest + "Source-Url: https://localhost:#{@port}/mock_plugin.tar.gz\n"

    cartridge      = OpenShift::Runtime::Manifest.new(manifest)
    cartridge_home = "/tmp/var/home/gear/mock"

    with_detail_output do
      OpenShift::CartridgeRepository.instantiate_cartridge(cartridge, cartridge_home)
    end

    assert_path_exist(cartridge_home)
    assert_path_exist(File.join(cartridge_home, 'bin', 'control'))
  end

  def with_detail_output
    begin
      yield
    rescue OpenShift::Utils::ShellExecutionException => e
      NodeLogger.logger.debug(e.message + "\n" +
                                  e.stdout + "\n" +
                                  e.stderr + "\n" +
                                  e.backtrace.join("\n")
      )
    end
  end
end
