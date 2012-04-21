require 'rubygems'
require 'fileutils'
require 'json'
require 'logger'
require 'open4'
require 'pp'
require 'rest-client'

include AppHelper

$cartridge_root ||= "/usr/libexec/stickshift/cartridges"
$jenkins_version = "jenkins-1.4"
$jenkins_cartridge = "#{$cartridge_root}/#{$jenkins_version}"
$jenkins_hooks = "#{$jenkins_cartridge}/info/hooks"
$jenkins_config_path = "#{$jenkins_hooks}/configure"
$jenkins_preconfig_path = "#{$jenkins_hooks}/preconfigure"
# app_name namespace acct_name
$jenkins_preconfig_format = "#{$jenkins_preconfig_path} '%s' '%s' '%s'"
$jenkins_config_format = "#{$jenkins_config_path} '%s' '%s' '%s'"
$jenkins_deconfig_path = "#{$jenkins_hooks}/deconfigure"
$jenkins_deconfig_format = "#{$jenkins_deconfig_path} '%s' '%s' '%s'"

$jenkins_start_path = "#{$jenkins_hooks}/start"
$jenkins_start_format = "#{$jenkins_start_path} '%s' '%s' '%s'"

$jenkins_stop_path = "#{$jenkins_hooks}/stop"
$jenkins_stop_format = "#{$jenkins_stop_path} '%s' '%s' '%s'"

$jenkins_status_path = "#{$jenkins_hooks}/status"
$jenkins_status_format = "#{$jenkins_status_path} '%s' '%s' '%s'"

When /^I configure a jenkins application$/ do
  account_name = @account['accountname']
  namespace = "ns1"
  app_name = "app1"
  @app = {
    'name' => app_name,
    'namespace' => namespace
  }
  command_formats = [$jenkins_preconfig_format, $jenkins_config_format]
  command_formats.each do |command_format|
    command = command_format % [app_name, namespace, account_name]
    buffer = []
    exit_code = runcon command,  $selinux_user, $selinux_role, $selinux_type, buffer
    raise Exception.new "Error running #{command}: Exit code: #{exit_code}" if exit_code != 0
  end
end

Given /^a new jenkins application$/ do
  account_name = @account['accountname']
  app_name = 'app1'
  namespace = 'ns1'
  @app = {
    'namespace' => namespace,
    'name' => app_name
  }
  command_formats = [$jenkins_preconfig_format, $jenkins_config_format]
  command_formats.each do |command_format|
    command = command_format % [app_name, namespace, account_name]
    runcon command, $selinux_user, $selinux_role, $selinux_type
  end
end

When /^I deconfigure the jenkins application$/ do
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']
  command = $jenkins_deconfig_format % [app_name, namespace, account_name]
  runcon command,  $selinux_user, $selinux_role, $selinux_type
end

When /^I (start|stop|restart) the jenkins service$/ do |action|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  command = "#{$jenkins_hooks}/%s %s %s %s" % [action, app_name, namespace, account_name]
  exit_status = runcon command, $selinux_user, $selinux_role, $selinux_type
  if exit_status != 0
    raise "Unable to %s for %s %s %s" % [action, app_name, namespace, account_name]
  end
  sleep 5
end

Given /^the jenkins service is (running|stopped)$/ do |start_state|
  account_name = @account['accountname']
  namespace = @app['namespace']
  app_name = @app['name']

  case start_state
  when 'running':
      fix_action = 'start'
      good_exit = 0
  when 'stopped':
      fix_action = 'stop'
      good_exit = 0
  end

  # check
  status_command = $jenkins_status_format %  [app_name, namespace, account_name]
  exit_status = runcon status_command, $selinux_user, $selinux_role, $selinux_type

  if exit_status != good_exit
    # fix it
    fix_command = "#{$jenkins_hooks}/%s %s %s %s" % [fix_action, app_name, namespace, account_name]
    exit_status = runcon fix_command, $selinux_user, $selinux_role, $selinux_type
    if exit_status != 0
      raise "Unable to %s for %s %s %s" % [fix_action, app_name, namespace, account_name]
    end
    sleep 5
    
    # check exit status
    exit_status = runcon status_command, $selinux_user, $selinux_role, $selinux_type
    if exit_status != good_exit
      raise "Received bad status (%d) after %s for %s %s %s" % [exit_status, fix_action, app_name, namespace, account_name]
    end
  end
end

Then /^a jenkins application directory will( not)? exist$/ do |negate|
  acct_name = @account['accountname']
  app_name = @app['name']

  app_root = "#{$home_root}/#{acct_name}/#{app_name}"
  status = (File.exists? app_root and File.directory? app_root) 
  # TODO - need to check permissions and SELinux labels

  if not negate
    status.should be_true "#{app_root} does not exist or is not a directory"
  else
    status.should be_false "file #{app_root} exists and is a directory.  it should not"
  end
end

Then /^the jenkins application directory tree will( not)? be populated$/ do |negate|
  # This directory should contain specfic elements:
  acct_name = @account['accountname']
  app_name = @app['name']

  app_root = "#{$home_root}/#{acct_name}/#{app_name}"

  file_list =  ['repo', 'run', 'tmp', 'data']

  file_list.each do |file_name| 
    file_path = app_root + "/" + file_name
    file_exists = File.exists? file_path
    unless negate
      file_exists.should be_true "file #{file_path} does not exist"
    else
      file_exists.should be_false "file #{file_path} exists, and should not"
    end
  end
end

Then /^a jenkins git repo will( not)? exist$/ do |negate|
  acct_name = @account['accountname']
  app_name = @app['name']

  git_root = "#{$home_root}/#{acct_name}/git/#{app_name}.git"
  file_exists = File.exists? git_root
  unless negate
    file_exists.should be_true "directory #{git_root} should exist and does not"
  else
    file_exists.should be_false "directory #{git_root} should not exist and does"
  end
end

Then /^the jenkins git hooks will( not)? exist$/ do |negate|
  acct_name = @account['accountname']
  app_name = @app['name']

  git_root = "#{$home_root}/#{acct_name}/git/#{app_name}.git"
  git_hook_dir = git_root + "/" + "hooks"
  hook_list = ["pre-receive", "post-receive"]

  hook_list.each do |file_name|
    file_path = "#{git_hook_dir}/#{file_name}"
    file_exists = File.exists? file_path
    unless negate
      file_exists.should be_true "file #{file_path} should exist and does not"
      file_exec = File.executable? file_path
      file_exec.should be_true "file #{file_path} should be executable and is not"
    else
      file_exists.should be_false "file #{file_path} should not exist and does"
    end
  end
end

Then /^the openshift environment variable files will( not)? exist$/ do |negate|
  acct_name = @account['accountname']
  app_name = @app['name']

  env_root = "#{$home_root}/#{acct_name}/.env"
  env_list = ["OPENSHIFT_GEAR_DIR", 
              "OPENSHIFT_REPO_DIR", 
              "OPENSHIFT_INTERNAL_IP",
              "OPENSHIFT_INTERNAL_PORT",
              "OPENSHIFT_LOG_DIR",
              "OPENSHIFT_DATA_DIR",
              "OPENSHIFT_TMP_DIR",
              "OPENSHIFT_RUN_DIR",
              "OPENSHIFT_GEAR_NAME",
              "OPENSHIFT_GEAR_CTL_SCRIPT",
              "JENKINS_URL"
              ]

  env_list.each do |file_name|
    file_path = "#{env_root}/#{file_name}"
    file_exists = File.exists? file_path
    unless negate
      file_exists.should be_true "file #{file_path} should exist and does not"
    else
      file_exists.should be_false "file #{file_path} should not exist and does"
    end
  end

end

Then /^a jenkins service startup script will( not)? exist$/ do |negate|
  acct_name = @account['accountname']
  app_name = @app['name']

  app_root = "#{$home_root}/#{acct_name}/#{app_name}"
  app_ctrl_script = "#{app_root}/#{app_name}_ctl.sh"

  file_exists = File.exists? app_ctrl_script
  unless negate
    file_exists.should be_true "file #{app_ctrl_script} should exist and does not"
    File.executable?(app_ctrl_script).should be_true "file #{app_ctrl_script} should be executable and is not"
  else
    file_exists.should be_false "file #{file_name} should not exist and does"
  end
end

Then /^a jenkins source tree will( not)? exist$/ do |negate|
  acct_name = @account['accountname']
  app_name = @app['name']

  app_root = "#{$home_root}/#{acct_name}/#{app_name}"
  repo_root_path = "#{app_root}/repo"

  unless negate
    File.exists?(repo_root_path).should be_true "file #{repo_root_path} should exist and does not"
    File.directory?(repo_root_path).should be_true "file #{repo_root_path} should be a directory and is not"
    src_root = Dir.new repo_root_path
    src_contents = ['README']

    src_contents.each do |file_name|
      src_root.member?(file_name).should be_true "file #{app_root}/repo/#{file_name} should exist and does not"
    end
  else
    File.exists?(repo_root_path).should be_false "file #{repo_root_path} should not exist and does"
  end
  
end

Then /^a jenkins application http proxy file will( not)? exist$/ do | negate |
  acct_name = @account['accountname']
  app_name = @app['name']
  namespace = @app['namespace']

  conf_file_name = "#{acct_name}_#{namespace}_#{app_name}.conf"
  conf_file_path = "#{$libra_httpd_conf_d}/#{conf_file_name}"

  unless negate
    File.exists?(conf_file_path).should be_true
  else
    File.exists?(conf_file_path).should be_false
  end
end

Then /^a jenkins application http proxy directory will( not)? exist$/ do |negate|
  acct_name = @account['accountname']
  app_name = @app['name']
  namespace = @app['namespace']

  conf_dir_path = "#{$libra_httpd_conf_d}/#{acct_name}_#{namespace}_#{app_name}"

  status = (File.exists? conf_dir_path and File.directory? conf_dir_path)
  # TODO - need to check permissions and SELinux labels

  if not negate
    status.should be_true "#{conf_dir_path} does not exist or is not a directory"
  else
    status.should be_false "file #{conf_dir_path} exists and is a directory.  it should not"
  end
end

Then /^a jenkins daemon will( not)? be running$/ do |negate|
  acct_name = @account['accountname']
  acct_uid = @account['uid']
  app_name = @app['name']

  max_tries = 7
  poll_rate = 3
  exit_test = negate ? lambda { |tval| tval == 0 } : lambda { |tval| tval > 0 }
  
  tries = 0
  num_javas = num_procs acct_name, "java"
  while (not exit_test.call(num_javas) and tries < max_tries)
    tries += 1
    sleep poll_rate
    found = exit_test.call num_javas
  end

  if not negate
    num_javas.should be > 0
  else
    num_javas.should be == 0
  end
end

Then /^the jenkins daemon log files will( not)? exist$/ do |negate|
  acct_name = @account['accountname']
  app_name = @app['name']

  log_dir = "#{$home_root}/#{acct_name}/#{app_name}/logs"
  log_list = ["jenkins.log"]

  log_list.each do |file_name|
    file_path = "#{log_dir}/#{file_name}"
    file_exists = File.exists? file_path
    unless negate
      file_exists.should be_true "file #{file_path} should exist and does not"
    else
      file_exists.should be_false "file #{file_path} should not exist and does"
    end
  end
end

When /^I configure a hello_world diy application with jenkins enabled$/ do
    @app = TestApp.create_unique('diy-0.1', 'diy')
    if rhc_create_domain(@app)
      @diy_app = rhc_create_app(@app, false, '--enable-jenkins --timeout=120')
    else
      raise "Failed to create domain: #{@app}"
    end

    output = `awk </tmp/rhc/cucumber.log '/^Job URL: / {print $3} /^Jenkins /,/^Note: / {if ($0 ~ /^ *User: /) print $2; if ($0 ~ /^ *Password: /) print $2;}'`.split("\n")
    @jenkins_user = output[-3]
    @jenkins_password = output[-2]
    @jenkins_url = output[-1]
    $logger.debug "@jenkins_url = #{@jenkins_url}\n@jenkins_user = #{@jenkins_user}\n@jenkins_password = #{@jenkins_password}"

    @jenkins_job_command = "curl -ksS -X GET #{@jenkins_url}api/json --user '#{@jenkins_user}:#{@jenkins_password}'"
    $logger.debug "@jenkins_job_command = #{@jenkins_job_command}"

    response = `#{@jenkins_job_command}`
    $logger.debug "@jenkins_job_command response = [#{response}]"

    job = JSON.parse(response)

    job.should_not be_nil
    job['name'].should be == 'diy-build', "#{job['name']} not equal to diy-build"
    job['color'].should be == 'grey', "job #{job['name']} has already been run."
end

When /^I push an update to the diy application$/ do
    output = `awk </tmp/rhc/cucumber.log '/^git url:.*diy.git.$/ {print $3}'`.split("\n")
    @diy_git_url = output[-1]

    FileUtils.rm_rf 'diy' if File.exists? 'diy'
    status = Open4::popen4("git clone #{@diy_git_url} diy") do |pid, stdin, stdout, stderr|
      $logger.debug "git clone: #{stdout.read}"
      $logger.info  "git clone: #{stderr.read}"
    end
    status.to_s.should be == "0"

    current = Dir.pwd
    begin
      Dir.chdir "diy"
      `sed -ie 's/Place your application here/Jenkins Builder Testing/' diy/index.html`

      status = Open4::popen4("git commit -a -m 'push to force build'") do |pid, stdin, stdout, stderr|
        $logger.debug "git commit: #{stdout.read}"
        $logger.info  "git commit: #{stderr.read}"
      end
      status.to_s.should be == "0"

      status = Open4::popen4("git push") do |pid, stdin, stdout, stderr|
        $logger.debug "git push: #{stdout.read}"
        $logger.info  "git push: #{stderr.read}"
      end
      status.to_s.should be == "0"
    rescue => e
      $logger.error "Unexpected exception: #{e.message}\n#{e.backtrace.join("\n")}"
      raise e
    ensure
      Dir.chdir current
      # todo: uncomment when done with development
      # FileUtils.rm_rf 'diy'
    end
end

Then /^the application will be updated$/ do
    # wait for ball to change blue...
    delay = 20
    begin
      sleep 1
      delay -= 1

      response = `#{@jenkins_job_command}`
      $logger.debug "@jenkins_job_command response = #{delay}[#{response}]"

      job = JSON.parse(response)
    end while job['color'] != 'blue' && 0 < delay
    job['color'].should be == 'blue' 

    path = "/var/lib/stickshift/#{@app.name}-#{@app.namespace}/#{@app.name}/runtime/repo/#{@app.name}/index.html"
    $logger.debug "jenkins built application path = #{path}"
    `grep 'Jenkins Builder Testing' "#{path}"`
    $?.to_s.should be == "0"
end

Then /^I deconfigure the diy application with jenkins enabled$/ do
    rhc_ctl_destroy(@app, false)
end
