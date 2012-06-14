require 'fileutils'

When /^the application is prepared for git pushes$/ do
  account_name = @account['accountname']
  app_name = @account['appnames'][0]
  namespace = @account['namespace']

  ssh_key = IO.read(File.expand_path("~/.ssh/id_rsa.pub")).chomp.split[1]
  run "echo \"127.0.0.1 #{app_name}-#{namespace}.dev.rhcloud.com # Added by cucumber\" >> /etc/hosts"
  run "ss-authorized-ssh-key-add -a #{account_name} -c #{account_name} -s #{ssh_key} -t ssh-rsa -m default"
  run "echo -e \"Host #{app_name}-#{namespace}.dev.rhcloud.com\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config"
end

When /^hot deployment is enabled for the (.+) application$/ do |type|
  pid_file = get_pid_file(type)

  File.exists?(pid_file).should be_true "#{type} pid file missing #{pid_file}"
  @app['pid'] = IO.read(pid_file).chomp
  @app['hot_deploy'] = true
end

When /^the (.+) application code is changed$/ do |type|
  # hack until we have a better lifecycle on the @node side
  @app['pid'] = IO.read(get_pid_file(type)).chomp unless @app.has_key?('pid')

  acct_name = @account['accountname']
  app_name = @app['name']
  namespace = @account['namespace']
  uuid = @account['accountname']

  tmp_git_root = "#{$temp}/#{acct_name}-#{app_name}-clone"

  run "git clone ssh://#{uuid}@#{app_name}-#{namespace}.dev.rhcloud.com/~/git/#{app_name}.git #{tmp_git_root}"

  marker_file = File.join(tmp_git_root, '.openshift', 'markers', 'hot_deploy')
  if @app.has_key?('hot_deploy') && @app['hot_deploy']
    FileUtils.touch(marker_file)
  else
    FileUtils.rm_f(marker_file)
  end

  Dir.chdir(tmp_git_root) do
    @update = "TEST"

    # Make a change to the app index file
    run "sed -i 's/Welcome/#{@update}/' #{get_index_file(type)}"
    run "git add ."
    run "git commit -m 'Test change'"
    run "git push"
  end
end

Then /^the (.+) application should( not)? change pids$/ do |type, negate|
  pid_file = get_pid_file(type)

  File.exists?(pid_file).should be_true "#{type} pid file missing #{pid_file}"
  current_pid = IO.read(pid_file).chomp
  if negate
    @app['pid'].should == current_pid
  else
    @app['pid'].should_not == current_pid
  end
end

def get_pid_file(type)
  pid_files_by_type = {
    "jbossas-7" => "jboss.pid",
    "php-5.3" => "httpd.pid",
    "nodejs-0.6" => "node.pid",
    "perl-5.10" => "httpd.pid",
    "python-2.6" => "httpd.pid",
    "ruby-1.8" => "httpd.pid",
    "ruby-1.9" => "httpd.pid"
  }

  raise "No pid filename is configured for cartridge type #{type}" unless pid_files_by_type.has_key?(type)

  acct_name = @account['accountname']
  app_name = @app['name']

  cart_instance_dir = "#{$home_root}/#{acct_name}/#{type}"
  pid_file = "#{cart_instance_dir}/run/#{pid_files_by_type[type]}"

  return pid_file
end
  
def get_index_file(type)
  index_files_by_type = {
    "php-5.3" => "php/index.php",
    "ruby-1.8" => "config.ru",
    "ruby-1.9" => "config.ru",
    "python-2.6" => "wsgi/application",
    "perl-5.10" => "perl/index.pl",
    "jbossas-7" => "src/main/webapp/index.html",
    "jbosseap-6.0" => "src/main/webapp/index.html",
    "nodejs-0.6" => "index.html"
  }

  raise "No index file configured for cartridge type #{type}" unless index_files_by_type.has_key?(type)
  
  return index_files_by_type[type]
end
