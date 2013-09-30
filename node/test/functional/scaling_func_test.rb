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
require 'restclient/request'

class ScalingFuncTest < OpenShift::NodeBareTestCase
  DEFAULT_TITLE     = "Welcome to OpenShift"
  CHANGED_TITLE     = "Test1"
  JENKINS_ADD_TITLE = "JenkinsClient"

  CART_TO_INDEX = {
    'jbossas-7'    => 'src/main/webapp/index.html',
    'jbosseap-6'   => 'src/main/webapp/index.html',
    'jbossews-1.0' => 'src/main/webapp/index.html',
    'jbossews-2.0' => 'src/main/webapp/index.html',
    'mock-0.1'     => 'index.html',
    'nodejs-0.6'   => 'index.html',
    'perl-5.10'    => 'perl/index.pl',
    'php-5.3'      => 'php/index.php',
    'python-2.6'   => 'wsgi/application',
    'python-2.7'   => 'wsgi/application',
    'python-3.3'   => 'wsgi/application',
    'ruby-1.8'     => 'config.ru',
    'ruby-1.9'     => 'config.ru',
    'zend-5.6'     => 'php/index.php',
  }

  def setup
    @tmp_dir = "/var/tmp-tests/#{Time.now.to_i}"
    FileUtils.mkdir_p(@tmp_dir)

    log_config = mock()
    log_config.stubs(:get).with("PLATFORM_LOG_CLASS").returns("StdoutLogger")
    ::OpenShift::Runtime::NodeLogger.stubs(:load_config).returns(log_config)

    @framework_cartridge = ENV['CART_TO_TEST'] || 'mock-0.1'
    OpenShift::Runtime::NodeLogger.logger.info("Using framework cartridge: #{@framework_cartridge}")

    @created_domain_names = []
    @created_app_ids = []

    @login = "user#{random_string}"
    @namespace = "ns#{random_string}"
    @url_base = "https://#{@login}:password@localhost/broker/rest"

    # create domain
    RestClient.post("#{@url_base}/domains", {name: @namespace}, accept: :json)
    @created_domain_names << @namespace
    OpenShift::Runtime::NodeLogger.logger.info("Created domain #{@namespace} for user #{@login}")
  end

  def teardown
    unless ENV['PRESERVE']
      response = RestClient.get("#{@url_base}/domains/#{@namespace}/applications", accept: :json)
      response = JSON.parse(response)

      response['data'].each do |app_data|
        id = app_data['id']
        OpenShift::Runtime::NodeLogger.logger.info("Deleting application id #{id}")
        RestClient.delete("#{@url_base}/applications/#{id}")
      end

      @created_domain_names.each do |name|
        OpenShift::Runtime::NodeLogger.logger.info("Deleting domain #{name}")
        RestClient.delete("#{@url_base}/domains/#{name}")
      end
    end
  end

  def test_unscaled_add_jenkins_no_keep()
    create_jenkins
    basic_build_test([@framework_cartridge], add_jenkins: true)
  end

  # def test_unscaled
  #   basic_build_test([@framework_cartridge], keep_deployments: 3)
  # end

  # def test_unscaled_jenkins
  #   create_jenkins
  #   basic_build_test([@framework_cartridge, 'jenkins-client-1'], keep_deployments: 3)
  # end

  # def test_scaled
  #   if @framework_cartridge == 'zend-5.6'
  #     return
  #   end

  #   basic_build_test([@framework_cartridge], scaling: true, keep_deployments: 3)
  # end

  # def test_scaled_jenkins
  #   if @framework_cartridge == 'zend-5.6'
  #     return
  #   end

  #   up_gears
  #   create_jenkins
  #   basic_build_test([@framework_cartridge, 'jenkins-client-1'], scaling: true, keep_deployments: 3)
  # end

  def create_jenkins
    app_name = "jenkins#{random_string}"
    create_application(app_name, %w(jenkins-1), false)
  end

  def basic_build_test(cartridges, options = {})
    scaling          = !!options[:scaling]
    add_jenkins      = !!options[:add_jenkins]
    keep_deployments = !!options[:keep_deployments]

    app_name = "app#{random_string}"

    app_id = create_application(app_name, cartridges, scaling)
    add_ssh_key(app_id, app_name)

    framework = cartridges[0]

    if keep_deployments
      keep = options[:keep_deployments]
      # keep up to 3 deployments
      `oo-admin-ctl-domain -l #{@login} -n #{@namespace} -c env_add -e OPENSHIFT_KEEP_DEPLOYMENTS -v #{keep}`
    end

    app_container = OpenShift::Runtime::ApplicationContainer.from_uuid(app_id)

    if scaling
      gear_registry = OpenShift::Runtime::GearRegistry.new(app_container)
      entries = gear_registry.entries
      OpenShift::Runtime::NodeLogger.logger.info("Gear registry contents: #{entries}")
      assert_equal 2, entries.keys.size

      web_entries = entries[:web]
      assert_equal 1, web_entries.keys.size
      assert_equal app_id, web_entries.keys[0]

      entry = web_entries[app_id]
      assert_equal app_id, entry.uuid
      assert_equal @namespace, entry.namespace
      assert_equal "#{app_name}-#{@namespace}.dev.rhcloud.com", entry.dns
      local_hostname = `facter public_hostname`.chomp
      assert_equal local_hostname, entry.proxy_hostname
      assert_equal IO.read(File.join(app_container.container_dir, '.env', 'OPENSHIFT_LOAD_BALANCER_PORT')).chomp, entry.proxy_port

      assert_http_title_for_entry entry, DEFAULT_TITLE

      proxy_entries = entries[:proxy]
      assert_equal 1, proxy_entries.keys.size
      assert_equal app_id, proxy_entries.keys[0]
      entry = proxy_entries[app_id]
      assert_equal app_id, entry.uuid
      assert_equal @namespace, entry.namespace
      assert_equal "#{app_name}-#{@namespace}.dev.rhcloud.com", entry.dns
      assert_equal local_hostname, entry.proxy_hostname
      assert_equal 0, entry.proxy_port.to_i

      # scale up to 2
      assert_scales_to app_name, framework, 2

      gear_registry.load
      entries = gear_registry.entries
      assert_equal 2, entries.keys.size
      web_entries = entries[:web]
      assert_equal 2, web_entries.keys.size

      # make sure the http content is good
      web_entries.values.each do |entry|
        OpenShift::Runtime::NodeLogger.logger.info("Checking title for #{entry.as_json}")
        assert_http_title_for_entry entry, DEFAULT_TITLE
      end
    else
      assert_http_title_for_app app_name, @namespace, DEFAULT_TITLE
    end

    deployment_metadata = app_container.deployment_metadata_for(app_container.current_deployment_datetime)
    deployment_id = deployment_metadata.id

    clone_repo(app_id)
    change_title(CHANGED_TITLE, app_name, app_id, framework)

    if scaling
      web_entries.values.each { |entry| assert_http_title_for_entry entry, CHANGED_TITLE }

      assert_scales_to app_name, framework, 3
      gear_registry.load
      entries = gear_registry.entries
      assert_equal 3, entries[:web].size

      entries[:web].values.each { |entry| assert_http_title_for_entry entry, CHANGED_TITLE }
    else
      assert_http_title_for_app app_name, @namespace, CHANGED_TITLE
    end

    if add_jenkins
      add_cartridge('jenkins-client-1', app_name)

      change_title(JENKINS_ADD_TITLE, app_name, app_id, framework)

      if scaling
        entries = gear_registry.entries
        entries[:web].values.each { |entry| assert_http_title_for_entry entry, JENKINS_ADD_TITLE }
      else
        assert_http_title_for_app app_name, @namespace, JENKINS_ADD_TITLE
      end
    end

    # rollback
    OpenShift::Runtime::NodeLogger.logger.info("Rolling back to #{deployment_id}")
    OpenShift::Runtime::NodeLogger.logger.info `ssh -o 'StrictHostKeyChecking=no' #{app_id}@localhost gear activate #{deployment_id}`

    if scaling
      entries = gear_registry.entries
      entries[:web].values.each { |entry| assert_http_title_for_entry entry, DEFAULT_TITLE }
    else
      assert_http_title_for_app app_name, @namespace, DEFAULT_TITLE      
    end
  end

  def add_cartridge(cartridge, app_name)
    OpenShift::Runtime::NodeLogger.logger.info("Adding #{cartridge} to app #{app_name}")
    response = RestClient::Request.execute(method: :post, url: "#{@url_base}/domain/#{@namespace}/application/#{app_name}/cartridges", payload: { name: cartridge, application_id: app_name, emb_cart: { name: cartridge }}, headers: { accept: :json }, timeout: 60)

    assert_operator 300, :>, response.code
  end

  def clone_repo(app_id)
    Dir.chdir(@tmp_dir) do
      response = RestClient.get("#{@url_base}/applications/#{app_id}", accept: :json)
      response = JSON.parse(response)
      git_url = response['data']['git_url']
      `git clone #{git_url}`
    end
  end

  def change_title(title, app_name, app_id, framework)
      # clone the git repo and make a change
    OpenShift::Runtime::NodeLogger.logger.info("Modifying the title to #{title} and pushing change")
    Dir.chdir(@tmp_dir) do
      Dir.chdir(app_name) do
        `sed -i "s,<title>.*</title>,<title>#{title}</title>," #{CART_TO_INDEX[framework]}`
        `git commit -am 'test1'`
        `git push`
      end
    end
  end

  def create_application(app_name, cartridges, scaling = true)
    OpenShift::Runtime::NodeLogger.logger.info("Creating app #{app_name} with cartridges: #{cartridges} with scaling: #{scaling}")
    # timeout is so high because creating a scalable python-3.3 app takes around 2.5 minutes
    # TODO: capture cart-specific timeouts / initial titles
    response = RestClient::Request.execute(method: :post, url: "#{@url_base}/domain/#{@namespace}/applications", payload: {name: app_name, cartridges: cartridges, scale: scaling}, headers: {accept: :json}, timeout: 180)
    response = JSON.parse(response)
    app_id = response['data']['id']
    @created_app_ids << app_id
    OpenShift::Runtime::NodeLogger.logger.info("Created app #{app_name} with id #{app_id}")

    app_id
  end

  def add_ssh_key(app_id, app_name)
    ssh_key = IO.read(File.expand_path('~/.ssh/id_rsa.pub')).chomp.split[1]
    `oo-devel-node authorized-ssh-key-add -c #{app_id} -k #{ssh_key} -T ssh-rsa -m default`
    File.open(File.expand_path('~/.ssh/config'), 'a', 0o0600) do |f|
      f.write <<END
Host #{app_name}-#{@namespace}.dev.rhcloud.com
  StrictHostKeyChecking no
END
    end  
  end

  def up_gears
    `oo-admin-ctl-user -l #{@login} --setmaxgears 5`
  end

  def random_string(len = 8)
    # Make sure this is an Array in case we pass a range
    charspace = ("1".."9").to_a
    (0...len).map{ charspace[rand(charspace.length)] }.join
  end

  def assert_http_title_for_entry(entry, expected)
    url = "http://#{entry.dns}:#{entry.proxy_port}/"
    assert_http_title(url, expected)
  end

  def assert_http_title_for_app(app_name, namespace, expected)
    url = "http://#{app_name}-#{@namespace}.dev.rhcloud.com"
    assert_http_title(url, expected)
  end

  def assert_http_title(url, expected)
    OpenShift::Runtime::NodeLogger.logger.info("Checking #{url} for title '#{expected}'")
    uri = URI.parse(url)

    tries = 1
    title = ''

    while tries < 3
      tries += 1
      content = ''

      begin
        content = Net::HTTP.get(uri)
      rescue SocketError => e
        OpenShift::Runtime::NodeLogger.logger.info("DNS lookup failure; retrying #{url}")
        next
      end

      content =~ /<title>(.+)<\/title>/
      title = $~[1]

      if title =~ /^503|404 / && tries < 3
        OpenShift::Runtime::NodeLogger.logger.info("Retrying #{url}")
      end

      break
    end

    assert_equal expected, title
  end

  def assert_scales_to(app_name, cartridge, count)
    OpenShift::Runtime::NodeLogger.logger.info("Scaling to #{count}")
    response = RestClient::Request.execute(method: :put, url: "#{@url_base}/domains/#{@namespace}/applications/#{app_name}/cartridges/#{cartridge}", payload: {scales_from: count}, headers: {accept: :json}, timeout: 180)
    response = JSON.parse(response)
    assert_equal count, response['data']['current_scale']
  end  
end
