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
require 'socket'
require 'net/http'
require 'fileutils'

class ScalingFuncTest < OpenShift::NodeBareTestCase
  def setup
    @tmp_dir = "/var/tmp-tests/#{Time.now.to_i}"
    FileUtils.mkdir_p(@tmp_dir)

    log_config = mock()
    log_config.stubs(:get).with("PLATFORM_LOG_CLASS").returns("StdoutLogger")
    ::OpenShift::Runtime::NodeLogger.stubs(:load_config).returns(log_config)

    @created_domain_names = []
    @created_app_ids = []

    login = "user#{random_string}"
    @namespace = "ns#{random_string}"
    @url_base = "https://#{login}:password@localhost/broker/rest"

    # create domain
    RestClient.post("#{@url_base}/domains", {name: @namespace}, accept: :json)
    @created_domain_names << @namespace
    OpenShift::Runtime::NodeLogger.logger.info("Created domain #{@namespace} for user #{login}")

    # keep up to 3 deployments
    `oo-admin-ctl-domain -l #{login} -n #{@namespace} -c env_add -e OPENSHIFT_KEEP_DEPLOYMENTS -v 3`
  end

  def teardown
    unless ENV['PRESERVE']
      @created_app_ids.each do |id|
        OpenShift::Runtime::NodeLogger.logger.info("Deleting application id #{id}")
        RestClient.delete("#{@url_base}/applications/#{id}")
      end

      @created_domain_names.each do |name|
        OpenShift::Runtime::NodeLogger.logger.info("Deleting domain #{name}")
        RestClient.delete("#{@url_base}/domains/#{name}")
      end
    end
  end

  def random_string(len = 8)
    # Make sure this is an Array in case we pass a range
    charspace = ("1".."9").to_a
    (0...len).map{ charspace[rand(charspace.length)] }.join
  end

  def local_ip
    addrinfo     = Socket.getaddrinfo(Socket.gethostname, 80) # 80 is arbitrary
    private_addr = addrinfo.select { |info|
      info[3] !~ /^127/
    }.first
    private_ip   = private_addr[3]
  end

  def assert_http_title_for_entry(entry, expected)
    OpenShift::Runtime::NodeLogger.logger.info("Checking http://#{entry.dns}:#{entry.proxy_port}/ for title '#{expected}'")
    content = Net::HTTP.get(entry.dns, '/', entry.proxy_port)
    content =~ /<title>(.+)<\/title>/
    title = $~[1]
    assert_equal expected, title
  end

  def assert_scales_to(app_name, count)
    OpenShift::Runtime::NodeLogger.logger.info("Scaling to #{count}")
    response = RestClient.put("#{@url_base}/domains/#{@namespace}/applications/#{app_name}/cartridges/ruby-1.9", {scales_from: count}, accept: :json)
    response = JSON.parse(response)
    assert_equal count, response['data']['current_scale']
  end

  def test_basic_scaling
    app_name = "app#{random_string}"

    # create scaled app
    OpenShift::Runtime::NodeLogger.logger.info("Creating app #{app_name}")
    response = RestClient.post("#{@url_base}/domains/#{@namespace}/applications", {name: app_name, cartridges: ['ruby-1.9'], scale: true}, accept: :json)
    response = JSON.parse(response)
    app_id = response['data']['id']
    @created_app_ids << app_id
    OpenShift::Runtime::NodeLogger.logger.info("Created app #{app_name} with id #{app_id}")

    ssh_key = IO.read(File.expand_path('~/.ssh/id_rsa.pub')).chomp.split[1]
    `oo-authorized-ssh-key-add -a #{app_id} -c #{app_id} -s #{ssh_key} -t ssh-rsa -m default`
    File.open(File.expand_path('~/.ssh/config'), 'a', 0o0600) do |f|
      f.write <<END
Host #{app_name}-#{@namespace}.dev.rhcloud.com
  StrictHostKeyChecking no
END
    end

    app_container = OpenShift::Runtime::ApplicationContainer.from_uuid(app_id)
    gear_registry = OpenShift::Runtime::GearRegistry.new(app_container)
    entries = gear_registry.entries
    assert_equal 1, entries.size
    entry = entries.values[0]
    OpenShift::Runtime::NodeLogger.logger.info("Gear registry contents: #{entry}")

    assert_equal app_id, entry.uuid
    assert_equal @namespace, entry.namespace
    assert_equal "#{app_name}-#{@namespace}.dev.rhcloud.com", entry.dns
    assert_equal local_ip, entry.private_ip
    assert_equal IO.read(File.join(app_container.container_dir, '.env', 'OPENSHIFT_LOAD_BALANCER_PORT')).chomp, entry.proxy_port

    assert_http_title_for_entry entry, "Welcome to OpenShift"

    # scale up to 2
    assert_scales_to app_name, 2

    gear_registry.load
    entries = gear_registry.entries
    assert_equal 2, entries.size

    # make sure the http content is good
    entries.values.each { |entry| assert_http_title_for_entry entry, "Welcome to OpenShift" }

    # clone the git repo and make a change
    OpenShift::Runtime::NodeLogger.logger.info("Modifying the title and pushing the change")
    Dir.chdir(@tmp_dir) do
      response = RestClient.get("#{@url_base}/applications/#{app_id}", accept: :json)
      response = JSON.parse(response)
      git_url = response['data']['git_url']
      `git clone #{git_url}`
      Dir.chdir(app_name) do
        `sed -i "s,<title>.*</title>,<title>Test1</title>," config.ru`
        `git commit -am 'test1'`
        `git push`
      end
    end

    # make sure the http content is updated
    entries.values.each { |entry| assert_http_title_for_entry entry, "Test1" }

    # scale up to 3
    assert_scales_to app_name, 3

    gear_registry.load
    entries = gear_registry.entries
    assert_equal 3, entries.size

    # make sure the http content is good
    entries.values.each { |entry| assert_http_title_for_entry entry, "Test1" }

    # rollback
    OpenShift::Runtime::NodeLogger.logger.info("Rolling back")
    OpenShift::Runtime::NodeLogger.logger.info `ssh -o 'StrictHostKeyChecking=no' #{app_id}@localhost gear rollback`

    # make sure the http content is rolled back
    entries.values.each { |entry| assert_http_title_for_entry entry, "Welcome to OpenShift" }
  end
end