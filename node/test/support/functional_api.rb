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

require 'test/unit/assertions'
require 'restclient/request'
require 'fileutils'
require 'net/http'
require 'json'
require 'openshift-origin-common/config'

class FunctionalApi
  include OpenShift::Runtime::NodeLogger
  include Test::Unit::Assertions

  attr_reader :login, :namespace, :url_base, :tmp_dir

  CARTS = {
    'jbossas-7' => {
      :index =>'src/main/webapp/index.html',
      :app_dir => 'deployments',
      :container_dir => 'jbossas',
    },
    'jbosseap-6' => {
      :index =>'src/main/webapp/index.html',
      :app_dir => 'deployments',
      :container_dir => 'jbosseap',
    },
    'jbossews-1.0' => {
      :index => 'src/main/webapp/index.html',
      :app_dir => 'webapps',
      :container_dir => 'jbossews',
    },
    'jbossews-2.0' =>  {
      :index => 'src/main/webapp/index.html',
      :app_dir => 'webapps',
      :container_dir => 'jbossews',
    },
    'mock-0.1' => {
      :index =>'index.html',
    },
    'nodejs-0.6' => {
      :index => 'index.html',
    },
    'nodejs-0.10' => {
      :index =>'index.html',
    },
    'perl-5.10' => {
      :index => 'perl/index.pl',
    },
    'php-5.3' => {
      :index => 'index.php',
    },
    'python-2.6' => {
      :index => 'wsgi.py',
    },
    'python-2.7' => {
      :index => 'wsgi.py',
    },
    'python-3.3' => {
      :index => 'wsgi.py',
    },
    'ruby-1.8' => {
      :index => 'config.ru',
    },
    'ruby-1.9' => {
      :index => 'config.ru',
    },
    'zend-5.6' => {
      :index =>'php/index.php',
    },
  }

  def initialize
    @login = "user#{random_string}"
    @namespace = "ns#{random_string}"
    @url_base = "https://#{@login}:password@localhost/broker/rest"
    @tmp_dir = "/var/tmp-tests/#{Time.now.to_i}"
    FileUtils.mkdir_p(@tmp_dir)
  end

  def register_user(login=nil, password=nil)
    if ENV['REGISTER_USER']
      if File.exists?("/etc/openshift/plugins.d/openshift-origin-auth-remote-user.conf")
        `/usr/bin/htpasswd -b /etc/openshift/htpasswd #{login} #{password}`
      elsif File.exists?("/etc/openshift/plugins.d/openshift-origin-auth-mongo.conf")
        `oo-register-user -l admin -p admin --username #{login} --userpass #{password}`
      else
        print "Unknown auth plugin. Not registering user #{$user}/#{$password}."
        print "Modify #{__FILE__}:37 if user registration is required."
      end
    end
  end

  def random_string(len = 8)
    # Make sure this is an Array in case we pass a range
    charspace = ("1".."9").to_a
    (0...len).map{ charspace[rand(charspace.length)] }.join
  end

  def create_domain
    register_user(@login,"password")
    RestClient.post("#{@url_base}/domains", {name: @namespace}, accept: :json)
    logger.info("Created domain #{@namespace} for user #{@login}")

    @namespace
  end

  def delete_domain
    response = RestClient.get("#{@url_base}/domains/#{@namespace}/applications", accept: :json)
    response = JSON.parse(response)

    response['data'].each do |app_data|
      id = app_data['id']
      logger.info("Deleting application id #{id}")
      RestClient.delete("#{@url_base}/applications/#{id}", {timeout: 480})
    end

    logger.info("Deleting domain #{@namespace}")
    RestClient.delete("#{@url_base}/domains/#{@namespace}")
  end

  def create_application(app_name, cartridges, scaling = true)
    logger.info("Creating app #{app_name} with cartridges: #{cartridges} with scaling: #{scaling}")
    # timeout is so high because creating a scalable python-3.3 app takes around 2.5 minutes
    # TODO: capture cart-specific timeouts / initial titles
    response = RestClient::Request.execute(method: :post, url: "#{@url_base}/domain/#{@namespace}/applications", payload: {name: app_name, cartridges: cartridges, scale: scaling}, headers: {accept: :json}, timeout: 180)
    response = JSON.parse(response)

    app_id = response['data']['id']
    logger.info("Created app #{app_name} with id #{app_id}")

    app_id
  end

  def configure_application(app_name, options)
    logger.info("Configuring application #{app_name} with config options #{options}")
    response = RestClient.put("#{@url_base}/domain/#{@namespace}/application/#{app_name}", options, accept: :json)
    assert_operator 300, :>, response.code, "Invalid response received: #{response}"
  end

  def clone_repo(app_id)
    Dir.chdir(@tmp_dir) do
      response = RestClient.get("#{@url_base}/applications/#{app_id}", accept: :json)
      response = JSON.parse(response)
      git_url = response['data']['git_url']
      `git clone #{git_url}`
    end
  end

  def add_ssh_key(app_id, app_name)
    ssh_key = IO.read(File.expand_path('~/.ssh/id_rsa.pub')).chomp.split[1]
    `oo-devel-node authorized-ssh-key-add -c #{app_id} -k #{ssh_key} -T ssh-rsa -m default`
    File.open(File.expand_path('~/.ssh/config'), 'a', 0o0600) do |f|
      ssh_config = <<EOFZ
Host #{app_name}-#{@namespace}.#{cloud_domain}
  StrictHostKeyChecking no
EOFZ
      f.write ssh_config
    end
  end

  def add_cartridge(cartridge, app_name)
    logger.info("Adding #{cartridge} to app #{app_name}")

    begin
      response = RestClient::Request.execute(method: :post,
                                             url: "#{@url_base}/domain/#{@namespace}/application/#{app_name}/cartridges",
                                             payload: JSON.dump(name: cartridge, application_id: app_name, emb_cart: { name: cartridge }),
                                             headers: { content_type: :json, accept: :json },
                                             timeout: 60)
    rescue RestClient::Exception => e
      response = e.response
    end

    assert_operator 300, :>, response.code, "Invalid response received: #{response}"
  end

  def add_env_vars(app_name, vars)
    logger.info("Adding environment variables to app #{app_name}: #{vars}")

    begin
      response = RestClient::Request.execute(method: :post,
                                             url: "#{@url_base}/domain/#{@namespace}/application/#{app_name}/environment-variables",
                                             payload: JSON.dump(environment_variables: vars),
                                             headers: { content_type: :json, accept: :json },
                                             timeout: 60)
    rescue RestClient::Exception => e
      response = e.response
    end

    assert_operator 300, :>, response.code, "Invalid response received: #{response}"
  end

  def gears_for_app(app_name)
    begin
      response = RestClient::Request.execute(method: :get,
                                             url: "#{@url_base}/domain/#{@namespace}/application/#{app_name}/gear_groups",
                                             headers: { accept: :json },
                                             timeout: 15)
    rescue RestClient::Exception => e
      response = e.response
    end

    logger.info("Response from gear GET for app: #{response}")

    assert_operator 300, :>, response.code, "Invalid response received: #{response}"

    gear_groups = JSON.load(response)

    gears = []
    gear_groups['data'].each do |group|
      group['gears'].each {|gear| gears << gear['id']}
    end

    gears.uniq
  end

  def change_title(title, app_name, app_id, framework)
    # clone the git repo and make a change
    logger.info("Modifying the title to #{title} and pushing change")
    Dir.chdir(@tmp_dir) do
      Dir.chdir(app_name) do
        `sed -i "s,<title>.*</title>,<title>#{title}</title>," #{CARTS[framework][:index]}`
        `git commit -am 'test1'`
        `git push origin master`
      end
    end
  end

  def up_gears(num=5)
    logger.info "Upping gears for #{@login}"
    logger.info `oo-admin-ctl-user -l #{@login} --setmaxgears #{num}`
  end

  def enable_ha
    logger.info "Enabling HA for test user #{@login}"
    logger.info `oo-admin-ctl-user -l #{@login} --allowha true`
  end

  def make_ha(app_name)
    begin
      response = RestClient::Request.execute(method: :post,
                                             url: "#{@url_base}/domains/#{@namespace}/applications/#{app_name}/events",
                                             payload: JSON.dump(event: 'make-ha'),
                                             headers: {content_type: :json, accept: :json},
                                             timeout: 180)
    rescue RestClient::Exception => e
      response = e.response
    end

    assert_operator 300, :>, response.code, "Invalid response received: #{response}"
  end

  def assert_http_title(url, expected, msg=nil, max_tries=10)
    logger.info("Checking #{url} for title '#{expected}'")
    uri = URI.parse(url)

    tries = 0
    title = ''

    while tries < max_tries
      tries += 1
      content = ''

      begin
        content = Net::HTTP.get(uri)
      rescue SocketError => e
        logger.info("DNS lookup failure; retrying #{url}")
        sleep 10
        next
      rescue Errno::ECONNREFUSED => e
        logger.info("connection refused; retrying #{url}")
        sleep 1
        next
      end

      content =~ /<title>(.+)<\/title>/
      title = $~[1] if $~

      if ((tries < max_tries) && (title =~ /^503|404 / || title != expected))
        logger.info("Not the response we wanted; retrying #{url}")
        sleep 1
        next
      end

      break
    end

    assert_equal expected, title, msg
  end

  def assert_http_title_for_entry(entry, expected, msg = nil, tries = 10)
    url = "http://#{entry.dns}:#{entry.proxy_port}/"
    assert_http_title(url, expected, msg, tries)
  end

  def assert_http_title_for_app(app_name, namespace, expected, msg = nil, tries = 10)
    url = "http://#{app_name}-#{namespace}.#{cloud_domain}"
    assert_http_title(url, expected, msg, tries)
  end

  def assert_scales_to(app_name, cartridge, count)
    logger.info("Scaling #{cartridge} in #{app_name} to #{count}")

    begin
      response = RestClient::Request.execute(method: :put,
                                             url: "#{@url_base}/domains/#{@namespace}/applications/#{app_name}/cartridges/#{cartridge}",
                                             payload: JSON.dump(scales_from: count),
                                             headers: {content_type: :json, accept: :json},
                                             timeout: 180)
    rescue RestClient::Exception => e
      raise "Exception scaling up: #{e.response}"
    end

    response = JSON.parse(response)
    assert_equal count, response['data']['current_scale']
  end

  def ssh_command(app_id, command)
    `ssh -o 'StrictHostKeyChecking=no' #{app_id}@localhost #{command}`
  end

  def save_deployment_snapshot_for_app(app_id, tgz_file_name="test.tgz")
    logger.info("Saving Deployment Snapshot Application(#{app_id}) as File(#{tgz_file_name})")
    ssh_command(app_id, "\"gear archive-deployment\" > #{tgz_file_name}")
    logger.info("Done Deployment Snapshot Application(#{app_id}) as File(#{tgz_file_name})")
  end

  def copy_file_to_apache(tgz_file_name="test.tgz")
    logger.info("Copying File(#{tgz_file_name}) to /var/www/html/binaryartifacts")
    `mkdir -p /var/www/html/binaryartifacts ; cp #{tgz_file_name} /var/www/html/binaryartifacts/`
    logger.info("Done Copying File(#{tgz_file_name}) to /var/www/html/binaryartifacts")
  end

  def deploy_binary_artifact_using_rest_api(app_name, artifact_url, hot_deploy=true)
    logger.info("Starting Deploy Binary Artifact Using REST API")
    url_endpoint = "#{@url_base}/domains/#{@namespace}/applications/#{app_name}/deployments"
    logger.info("Posting to URL(#{url_endpoint}) to Deploy with the Downloadable Artifact URL(#{artifact_url})")

    begin
      response = RestClient::Request.execute(method: :post,
                                             url: url_endpoint,
                                             payload: JSON.dump(artifact_url: artifact_url, hot_deploy: hot_deploy),
                                             headers: {content_type: :json, accept: :json},
                                             timeout: 180)
    rescue RestClient::Exception => e
      raise "Exception binary deployment up: #{e.response}"
    end

    response = JSON.parse(response)
    logger.info("Got Response(#{response})")
    logger.info("Done Deploy Binary Artifact Using REST API")
  end

  def deploy_artifact(app_id, app_name, file, hot_deploy=false)
    logger.info("Deploying #{file} to app #{app_name}")
    hot = hot_deploy ? '--hot-deploy' : ''
    result = `cat #{file} | ssh -o 'StrictHostKeyChecking=no' #{app_id}@localhost gear binary-deploy #{hot}`
    logger.info(result)
  end

  def clean_binary_archive(file, framework)
    if !CARTS[framework][:app_dir] && !CARTS[framework][:container_dir]
      delete_openshift_dir(file)
    else
      recreate_archive(file, framework)
    end
  end

  def recreate_archive(file, framework)
    logger.info("Recreating archive #{file}")
    ext_tmp_dir = "/tmp/#{Time.now.to_i}"
    FileUtils.mkdir_p(ext_tmp_dir)
    `tar -xzf #{file} -C #{ext_tmp_dir}`
    # repo/[deployments|webapps]/*
    src = File.join(ext_tmp_dir, "repo", CARTS[framework][:app_dir])
    # dependencies/[jbossas|jbossews]
    dst = File.join(ext_tmp_dir, "dependencies", CARTS[framework][:container_dir], CARTS[framework][:app_dir])
    `mv -f #{src}/* #{dst}/`
    FileUtils.rm_rf(File.join(ext_tmp_dir, "repo"))
    `cd #{ext_tmp_dir} && tar -czf #{file} * && cd $HOME`
    FileUtils.rm_rf(ext_tmp_dir)
  end

  def delete_openshift_dir(file)
     logger.info("Removing .openshift dir from #{file}")
    `gunzip -c #{file} | tar --delete "./repo/.openshift" | gzip > #{file}2 && mv #{file}2 #{file}`
  end

  def cloud_domain
    ::OpenShift::Config.new.get('CLOUD_DOMAIN')
  end

  def assert_gear_status_in_proxy(proxy, target_gear, status)
    passed = false
    num_tries = 3
    (1..num_tries).each do |i|
      proxy_status_csv = `curl "http://#{proxy.dns}/haproxy-status/;csv" 2>/dev/null`

      if proxy.uuid == target_gear.uuid
        names = [ 'local-gear' ]
      else
        gear_name = target_gear.dns.split('-')[0]
        names = [ "gear-#{gear_name}-#{target_gear.namespace}" ]
        gear_name = proxy.dns.split('-')[0]
        names << "gear-#{gear_name}-#{target_gear.namespace}"
      end

      proxy_status_csv.split("\n").each do |line|
        names.each do |name|
          if line =~ /#{name}/
            if line =~ /#{status}/
              passed = true
            elsif i == num_tries
              assert_match /#{status}/, line
            end
            break
          end
        end
      end
      break if passed
      sleep 2
    end

    flunk("Target gear #{target_gear.name} did not have expected status #{status}") unless passed
  end

  def restart_cartridge(app_name, cartridge)
    logger.info("Restarting #{cartridge} in #{app_name}")

    begin
      response = RestClient::Request.execute(method: :post,
                                             url: "#{@url_base}/domains/#{@namespace}/applications/#{app_name}/cartridges/#{cartridge}/events",
                                             payload: JSON.dump(event: 'restart'),
                                             headers: {content_type: :json, accept: :json},
                                             timeout: 180)
    rescue RestClient::Exception => e
      raise "Exception restarting: #{e.response}"
    end

    response = JSON.parse(response)
    assert_equal 'ok', response['status']
  end
end
