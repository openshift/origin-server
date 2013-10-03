require 'test/unit/assertions'
require 'restclient/request'
require 'fileutils'
require 'net/http'
require 'json'

class FunctionalApi
  include OpenShift::Runtime::NodeLogger
  include Test::Unit::Assertions

  attr_reader :login, :namespace, :url_base, :tmp_dir

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

  def initialize
    @login = "user#{random_string}"
    @namespace = "ns#{random_string}"
    @url_base = "https://#{@login}:password@localhost/broker/rest"
    @tmp_dir = "/var/tmp-tests/#{Time.now.to_i}"
    FileUtils.mkdir_p(@tmp_dir)
  end

  def random_string(len = 8)
    # Make sure this is an Array in case we pass a range
    charspace = ("1".."9").to_a
    (0...len).map{ charspace[rand(charspace.length)] }.join
  end

  def create_domain
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
      RestClient.delete("#{@url_base}/applications/#{id}")
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
Host #{app_name}-#{@namespace}.dev.rhcloud.com
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
        `sed -i "s,<title>.*</title>,<title>#{title}</title>," #{CART_TO_INDEX[framework]}`
        `git commit -am 'test1'`
        `git push`
      end
    end
  end

  def up_gears
    `oo-admin-ctl-user -l #{@login} --setmaxgears 5`
  end

  def assert_http_title(url, expected)
    logger.info("Checking #{url} for title '#{expected}'")
    uri = URI.parse(url)

    tries = 1
    title = ''

    while tries < 3
      tries += 1
      content = ''

      begin
        content = Net::HTTP.get(uri)
      rescue SocketError => e
        logger.info("DNS lookup failure; retrying #{url}")
        next
      end

      content =~ /<title>(.+)<\/title>/
      title = $~[1]

      if title =~ /^503|404 / && tries < 3
        logger.info("Retrying #{url}")
      end

      break
    end

    assert_equal expected, title
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
end
