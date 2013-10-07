# Support steps for runtime-centric tests.
#
# IMPORTANT: The steps defined here are for basic sanity checks of a 
# SINGLE application with a SINGLE gear and cartridge, and all work 
# in the context of these assumptions. If your test needs more complex 
# setups, write some more steps which are more flexible.

require 'fileutils'
require 'openshift-origin-node/utils/application_state'
require 'openshift-origin-node/utils/shell_exec'
require 'pty'
require 'digest/md5'
require 'openssl'
require 'httpclient'

# These are provided to reduce duplication of code in feature files.
#   Scenario Outlines are not used as they interfer with the devenv retry logic (whole feature is retried no example line)

Given /^a new ([^ ]+) application, verify create and delete using ([^ ]+)$/ do |cart_name, proc_name|
  steps %Q{
    Given a new #{cart_name} type application
    Then the http proxy will exist
    And a #{proc_name} process will be running
    And the application git repo will exist
    And the application source tree will exist
    And the application log files will exist
    When I destroy the application
    Then the http proxy will not exist
    And a #{proc_name} process will not be running
    And the application git repo will not exist
    And the application source tree will not exist
  }
end

Given /^a new ([^ ]+) application, verify start, stop, restart using ([^ ]+)$/ do |cart_name, proc_name|
  steps %Q{
    Given a new #{cart_name} type application
    Then a #{proc_name} process will be running
    When I stop the application
    Then a #{proc_name} process will not be running
    When I start the application
    Then a #{proc_name} process will be running
    When I status the application
    Then a #{proc_name} process will be running
    When I restart the application
    Then a #{proc_name} process will be running
    When I destroy the application
    Then the http proxy will not exist
    And a #{proc_name} process will not be running
  }
end

Given /^an existing ([^ ]+) application, verify its namespace cannot be changed$/ do |cart_name|
  steps %{
    Given an existing #{cart_name} application
    When the application namespace is updated
    Then the application should be accessible
  }
end

Given /^a new ([^ ]+) application, verify rhcsh$/ do |cart_name|
  steps %{
    Given a new #{cart_name} type application
    And the application is made publicly accessible

    Then I can run "ls / > /dev/null" with exit code: 0
    And I can run "this_should_fail" with exit code: 127
    And I can run "true" with exit code: 0
    And I can run "java -version" with exit code: 0
    And I can run "scp" with exit code: 1
  }
end

Given /^a new ([^ ]+) application, verify tail logs$/ do |cart_name|
  steps %{
    Given a new #{cart_name} type application
    And the application is made publicly accessible
    Then a tail process will not be running

    When I tail the logs via ssh
    Then a tail process will be running

    When I stop tailing the logs
    Then a tail process will not be running
  }
end

Given /^a new ([^ ]+) application, obtain disk quota information via SSH$/ do |cart_name|
  steps %{
    Given a new #{cart_name} type application
    And the application is made publicly accessible
    Then I can obtain disk quota information via SSH
  }
end

# Creates a new account, application, gear, and cartridge in one shot.
# The cartridge is then configured. After running this step, subsequent
# steps will have access to three pieces of state:
#
#   @account: a TestAccount instance with randomly generated properties
#   @app: a TestApplication instance associated with @account
#   @gear: a TestGear instance associated with @app
#   @cart: a TestCartridge instance associated with @gear
#
# The type of cartridge created will be of type cart_name from the step
# matcher.
Given /^a(n additional)? new ([^ ]+) type application$/ do | additional, cart_name |
  record_measure("Runtime Benchmark: Creating cartridge #{cart_name}") do
    if additional 
      assert_not_nil @account, 'You must create a new application before an additional application can be created'
    else
      @account = OpenShift::TestAccount.new
      @app = @account.create_app
    end

    @gear = @app.create_gear

    @cart = @gear.add_cartridge(cart_name)
    @cart.configure
  end
end

Given /^a new cli-created ([^ ]+) type application$/ do |cart_name|
  record_measure("Runtime Benchmark: Creating cartridge #{cart_name} with CLI tools") do
    @account = OpenShift::TestAccount.new
    @app = @account.create_app
    @gear = @app.create_gear(true)
    @cart = @gear.add_cartridge(cart_name)
    @cart.configure(true)
  end
end

# Invokes destroy on the current application.
When /^I destroy the application$/ do
  record_measure("Runtime Benchmark: Destroying cartridge #{@cart.name}") do
    @app.destroy
  end
end

# Embeds a new cartridge to the current application's gear
# Calls configure on the embedded cartridge.
When /^I (fail to )?embed a ([^ ]+) cartridge into the application$/ do | negate, cart_name |
  record_measure("Runtime Benchmark: Configure #{cart_name} cartridge in cartridge #{@cart.name}") do
    cart = @gear.add_cartridge(cart_name)

    if negate
      assert_raise(OpenShift::Runtime::Utils::ShellExecutionException) do
        exit_code = cart.configure
      end
    else
      cart.configure
    end
  end
end

# Un-embeds a cartridge from the current application's gear by 
# invoking deconfigure on the named cartridge.
When /^I remove the ([^ ]+) cartridge from the application$/ do | cart_name |
  record_measure("Runtime Benchmark: Deconfigure #{cart_name} cartridge in cartridge #{@cart.name}") do
    raise "No embedded cart named #{cart_name} associated with gear #{@gear.uuid}" unless @gear.carts.has_key?(cart_name)

    embedded_cart = @gear.carts[cart_name]

    embedded_cart.deconfigure
  end
end

# Verifies the existence of the httpd proxy
Then /^the http proxy ?([^ ]+)? will( not)? exist$/ do | path, negate |
  paths = @gear.list_http_proxy_paths

  if path == nil
    path = ""
  end

  $logger.info("Checking for #{negate} proxy #{path}")
  if negate
    assert_not_includes(paths, path)
  else
    assert_includes(paths, path)
  end
end

# Verifies the existence of a git repo associated with the current
# application.
Then /^the application git repo will( not)? exist$/ do | negate |
  git_repo = "#{$home_root}/#{@gear.uuid}/git/#{@app.name}.git"

  # TODO - need to check permissions and SELinux labels

  $logger.info("Checking for #{negate} git repo at #{git_repo}")
  if negate
    refute_directory_exist git_repo
  else
    assert_directory_exist git_repo
  end
end


# Verifies the existence of an exported source tree associated with
# the current application.
Then /^the application source tree will( not)? exist$/ do | negate |
  cartridge = @gear.carts[@cart.name]
  app_root = "#{$home_root}/#{@gear.uuid}/#{cartridge.directory}"

  # TODO - need to check permissions and SELinux labels

  $logger.info("Checking for app root at #{app_root}")
  if negate
    refute_directory_exist app_root
  else
    assert_directory_exist app_root
  end
end


# Verifies the existence of application log files associated with the
# current application.
Then /^the application log files will( not)? exist$/ do | negate |
  cartridge = @gear.carts[@cart.name]
  log_dir_path = "#{$home_root}/#{@gear.uuid}/#{cartridge.directory}/logs"

  $logger.info("Checking for log dir at #{log_dir_path}")

  begin
    log_dir = Dir.new log_dir_path
    status = (log_dir.count > 2)
  rescue
    status = false
  end

  if not negate
    status.should be_true
  else
    status.should be_false
  end
end


# Ensures that the root directory exists for the given embedded cartridge.
Then /^the embedded ([^ ]+) cartridge directory will( not)? exist$/ do | cart_name, negate |
  cartridge = @gear.carts[cart_name]
  user_root = "#{$home_root}/#{@gear.uuid}/#{cartridge.directory}"

  $logger.info("Checking for #{negate} cartridge root dir at #{user_root}")
  if negate
    refute_directory_exist user_root
  else
    assert_directory_exist user_root
  end
end


# Ensures that more than zero log files exist in the given embedded cartridge
# log directory.
Then /^the embedded ([^ ]+) cartridge log files will( not)? exist$/ do | cart_name, negate |
  cartridge = @gear.carts[cart_name]
  log_dir_path = "#{$home_root}/#{@gear.uuid}/#{cartridge.directory}/logs"

  $logger.info("Checking for #{negate} cartridge log dir at #{log_dir_path}")
  if negate
    refute_directory_exist log_dir_path
  else
    assert_directory_exist log_dir_path
  end
end


# Simple verification of arbitrary cartridge directory existence.
Then /^the embedded ([^ ]+) cartridge subdirectory named ([^ ]+) will( not)? exist$/ do | cart_name, dir_name, negate |
  cartridge = @gear.carts[cart_name]
  dir_path = "#{$home_root}/#{@gear.uuid}/#{cartridge.directory}/#{dir_name}"

  $logger.info("Checking for #{negate} cartridge subdirectory at #{dir_path}")
  if negate
    refute_directory_exist dir_path
  else
    assert_directory_exist dir_path
  end
end


# Ensures that the named control script exists for the given embedded cartridge of the
# current application.
Then /^the embedded ([^ ]+)\-([\d\.]+) cartridge control script will( not)? exist$/ do |cart_type, cart_version, negate|
  # rewrite for 10gen-mms-agent
  cooked = cart_type.gsub('-', '_')
  startup_file = File.join($home_root,
                           @gear.uuid,
                           "#{cart_type}-#{cart_version}",
                          "#{@app.name}_#{cooked}_ctl.sh")

  $logger.info("Checking for #{negate} cartridge control script at #{startup_file}")
  if negate
    refute_file_exist startup_file
  else
    assert_file_exist startup_file
  end
end


# Used to control the runtime state of the current application.
#
# IMPORTANT: As mentioned in the general comments, this step assumes
# a single application/gear/cartridge, and does its work by controlling
# the single cartridge directly. There will be no recursive actions for
# multiple carts associated with an app/gear.
When /^I (start|stop|status|restart|call tidy on) the application$/ do |action|
  # XXX FIXME: hack necessary due to ambiguous step definition
  # w/ application_steps.rb
  if ('call tidy on' == action)
    action = 'tidy'
  end

  OpenShift::timeout(60) do
    record_measure("Runtime Benchmark: Hook #{action} on application #{@cart.name}") do
      @cart.send(action)
    end
  end
end


# Controls carts within the current gear directly, by cartridge name.
# The same comments from the similar matcher apply.
When /^I (start|stop|status|restart) the ([^ ]+) cartridge$/ do |action, cart_name|
  record_measure("Runtime Benchmark: Hook #{action} on cart #{@cart.name}") do
    @gear.carts[cart_name].send(action)
  end
end


# Verifies that a process named proc_name and associated with the current
# application will be running (or not). The step will retry up to max_tries
# times to verify the expectations, as some cartridge stop hooks are
# asynchronous. This doesn't outright eliminate timing issues, but it helps.
Then /^a (.+) process will( not)? be running$/ do | proc_name, negate |
  exit_test = negate ? lambda { |tval| tval == 0 } : lambda { |tval| tval > 0 }
  exit_test_desc = negate ? "0" : ">0"

  num_node_processes = num_procs @gear.uuid, proc_name
  $logger.info("Expecting #{exit_test_desc} pid(s) named #{proc_name}, found #{num_node_processes}")
  OpenShift::timeout(20) do
    while (not exit_test.call(num_node_processes))
      $logger.info("Waiting for #{proc_name} process count to be #{exit_test_desc}")
      sleep 1 
      num_node_processes = num_procs @gear.uuid, proc_name
    end
  end

  if not negate
    num_node_processes.should be > 0
  else
    num_node_processes.should be == 0
  end
end


# Verifies that a process named proc_name and associated with the current
# application will be running (or not). The step will retry up to max_tries
# times to verify the expectations, as some cartridge stop hooks are
# asynchronous. This doesn't outright eliminate timing issues, but it helps.
Then /^a (.+) process for ([^ ]+) will( not)? be running$/ do | proc_name, label, negate |
  exit_test = negate ? lambda { |tval| tval == 0 } : lambda { |tval| tval > 0 }
  exit_test_desc = negate ? "0" : ">0"

  num_node_processes = num_procs @gear.uuid, proc_name, label
  $logger.info("Expecting #{exit_test_desc} pid(s) named #{proc_name}, found #{num_node_processes}")
  OpenShift::timeout(20) do
    while (not exit_test.call(num_node_processes))
      $logger.info("Waiting for #{proc_name} process count to be #{exit_test_desc}")
      sleep 1 
      num_node_processes = num_procs @gear.uuid, proc_name, label
    end
  end

  if not negate
    num_node_processes.should be > 0
  else
    num_node_processes.should be == 0
  end
end

# Verifies that exactly the specified number of the named processes
# are currently running.
#
# Could maybe be consolidated with the other similar step with some
# good refactoring.
Then /^(\d+) process(es)? named ([^ ]+) will be running$/ do | proc_count, junk, proc_name |
  proc_count = proc_count.to_i

  num_node_processes = num_procs @gear.uuid, proc_name
  $logger.info("Expecting #{proc_count} pid(s) named #{proc_name}, found #{num_node_processes}")
  OpenShift::timeout(20) do
    while (num_node_processes != proc_count)
      $logger.info("Waiting for #{proc_name} process count to equal #{proc_count}")
      sleep 1
      num_node_processes = num_procs @gear.uuid, proc_name
    end
  end
  
  num_node_processes.should be == proc_count
end

# Verifies that exactly the specified number of the named processes
# with arguments matching 'label' are currently running.
#
# Could maybe be consolidated with the other similar step with some
# good refactoring.
Then /^(\d+) process(es)? named ([^ ]+) for ([^ ]+) will be running$/ do | proc_count, junk, proc_name, label |
  proc_count = proc_count.to_i

  num_node_processes = num_procs @gear.uuid, proc_name, label
  $logger.info("Expecting #{proc_count} pid(s) named #{proc_name}, found #{num_node_processes}")
  OpenShift::timeout(20) do
    while (num_node_processes != proc_count)
      $logger.info("Waiting for #{proc_name} process count to equal #{proc_count}")
      sleep 1
      num_node_processes = num_procs @gear.uuid, proc_name, label
    end
  end
  
  num_node_processes.should be == proc_count
end


# Makes the application publicly accessible.
#
#   - Adds an /etc/hosts entry for the application to work around
#     the lack of DNS
#   - Adds the test pubkey to the authorized key list for the host
#   - Disables strict host key checking for the host to suppress
#     interactive prompts on push
#
# This is not pretty. If it can be made less hackish and faster, it
# could be moved into the generic application setup step.
When /^the application is made publicly accessible$/ do
  ssh_key = IO.read($test_pub_key).chomp.split[1]
  run "echo \"127.0.0.1 #{@app.name}-#{@account.domain}.#{$cloud_domain} # Added by cucumber\" >> /etc/hosts"
  run "oo-devel-node authorized-ssh-key-add -c #{@gear.uuid} -k #{ssh_key} -T ssh-rsa -m default"
  run "echo -e \"Host #{@app.name}-#{@account.domain}.#{$cloud_domain}\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config"
end

When /^the application is prepared for git pushes$/ do
  @app.git_repo = "#{$temp}/#{@account.name}-#{@app.name}-clone"
  run "git clone ssh://#{@gear.uuid}@#{@app.name}-#{@account.domain}.#{$cloud_domain}/~/git/#{@app.name}.git #{@app.git_repo}"

  Dir.chdir(@app.git_repo) do
    if `git --version`.match("git version 1.8")
      run "git config --global push.default simple"
    end
    run "git config --global user.name 'Cucumber'"
    run "git config --global user.email 'cucumber@example.com'"
  end
end


# Captures the current cartridge PID hash for the test application and
# makes it accessible to other steps via @current_cart_pids.
When /^the application cartridge PIDs are tracked$/ do 
  @current_cart_pids = @app.current_cart_pids

  $logger.info("Tracking current cartridge pids for application #{@app.name}: #{@current_cart_pids.inspect}")
end


# Toggles hot deployment for the current application.
When /^hot deployment is( not)? enabled for the application$/ do |negate|
  @app.hot_deploy_enabled = negate ? false : true
  $logger.info("Hot deployment #{@app.hot_deploy_enabled ? 'enabled' : 'disabled'} for application #{@app.name}")
end


# Expands the "simple update" step and adds hot deployment stuff for legacy carts.
When /^an update (is|has been) pushed to the application repo$/ do |junk|
  record_measure("Runtime Benchmark: Updating #{$temp}/#{@account.name}-#{@app.name} source") do
    steps %{
    When the application is prepared for git pushes
    }

    marker_file = File.join(@app.git_repo, '.openshift', 'markers', 'hot_deploy')

    if @app.hot_deploy_enabled
      FileUtils.touch(marker_file)
    else
      FileUtils.rm_f(marker_file)
    end

    steps %{
    When a simple update is pushed to the application repo
    }
  end
end

# Performs a trivial update to the test application source by appending
# some random stuff to a dummy file. The change is then committed and 
# pushed to the app's Git repo.
When /^a simple update is pushed to the application repo$/ do
  record_measure("Runtime Benchmark: Pushing random change to app repo at #{@app.git_repo}") do
    Dir.chdir(@app.git_repo) do
      commit_simple_change
      push_output = `git push`
      $logger.info("Push output:\n#{push_output}")
    end
  end
end

When /^a simple update is committed to the application repo$/ do
  record_measure("Runtime Benchmark: Committing random change to app repo at #{@app.git_repo}") do
    commit_simple_change
  end
end

When /^the hot_deploy marker is (added to|removed from) the application repo$/ do |op|
  Dir.chdir(@app.git_repo) do
    marker_file = File.join(@app.git_repo, '.openshift', 'markers', 'hot_deploy')
    marker_dir = File.dirname(marker_file)
    FileUtils.mkdir_p(marker_dir) if not Dir.exists?(marker_dir)
    ENV['X_SCLS'] = nil
    
    if op == "added to"
      if !File.exists?(marker_file)
        run "touch #{marker_file}"
        run "git add ."
        run "git commit -m 'Add hot_deploy marker'"
      end
    else
      if File.exists?(marker_file)
        run "git rm -f #{marker_file}"
        run "git commit -m 'Remove hot_deploy marker'"
      end
    end
  end
end

When /^the application git repository is pushed$/ do
  record_measure("Runtime Benchmark: Pushing app repo at #{@app.git_repo}") do
    Dir.chdir(@app.git_repo) do
      push_output = `git push`
      $logger.info("Push output:\n#{push_output}")
    end
  end
end

# Adds/removes aliases from the application
When /^I add an alias to the application/ do
  server_alias = "#{@app.name}.#{$alias_domain}"

  @gear.add_alias(server_alias)
end


# Adds/removes aliases from the application
When /^I remove an alias from the application/ do
  server_alias = "#{@app.name}.#{$alias_domain}"

  @gear.remove_alias(server_alias)
end


# Asserts the 'cucumber_update_test' file exists after an update
Then /^the application repo has been updated$/ do
  assert_file_exist File.join($home_root,
                              @gear.uuid,
                              'app-root',
                              'runtime',
                              'repo',
                              'cucumber_update_test')
end

# Compares the current PID set for the test application to whatever state
# was last captured and stored in @current_cart_pids. Raises exceptions
# depending on the expectations configured by the matcher.
Then /^the tracked application cartridge PIDs should( not)? be changed$/ do |negate|
  diff_expected = !negate # better way to do this?

  new_cart_pids = @app.current_cart_pids

  $logger.info("Comparing old and new PIDs for #{@app.name}, diffs are #{diff_expected ? 'expected' : 'unexpected' }." \
    " Old PIDs: #{@current_cart_pids.inspect}, new PIDs: #{new_cart_pids.inspect}")

  diffs = []

  @current_cart_pids.each do |proc_name, old_pid|
    new_pid = new_cart_pids[proc_name]

    if !new_pid || (new_pid != old_pid)
      diffs << proc_name
    end
  end

  if !diff_expected && diffs.length > 0
    raise "Expected no PID differences, but found #{diffs.length}. Old PIDs: #{@current_cart_pids.inspect},"\
      " new PIDs: #{new_cart_pids.inspect}"
  end

  if diff_expected && diffs.length == 0
    raise "Expected PID differences, but found none. Old PIDs: #{@current_cart_pids.inspect},"\
      " new PIDs: #{new_cart_pids.inspect}"
  end

  # verify BZ852268 fix
  state_file = File.join($home_root, @gear.uuid, 'app-root', 'runtime', '.state')
  state = File.read(state_file).chomp
  assert_equal 'started', state
end

Then /^the web console for the ([^ ]+)\-([\d\.]+) cartridge at ([^ ]+) is( not)? accessible$/ do |cart_type, version, uri, negate|

  url = "https://127.0.0.1#{uri}"

  finished = negate ? lambda { |s| s == "503" } : lambda { |s| s == "200"}
  cmd = "curl -L -k -w %{http_code} -s -o /dev/null -H 'Host: #{@app.name}-#{@account.domain}.#{$domain}' #{url}"
  res = `#{cmd}`
  OpenShift::timeout(300) do
    while not finished.call res
      res = `#{cmd}`
      $logger.debug { "Waiting on #{cart_type} to#{negate} be accessible: status #{res}" }
      sleep 1
    end 
  end

  msg = "Unexpected response from #{cmd}"
  if negate
    assert_equal "503", res, msg
  else
    assert_equal "200", res, msg
  end
end

#####################
# V2-focused steps
#####################

def ssh_command(command) 
  "ssh 2>/dev/null -o BatchMode=yes -o StrictHostKeyChecking=no -tt #{@gear.uuid}@#{@app.name}-#{@account.domain}.#{$cloud_domain} " + command
end

def assert_app_env_var(var_name, prefix = true)
  if prefix
    var_name = "OPENSHIFT_#{var_name}"
  end

  var_file_path = File.join($home_root, @gear.uuid, '.env', var_name)

  assert_file_exist var_file_path
end

def refute_app_env_var(var_name, prefix = true)
  if prefix
    var_name = "OPENSHIFT_#{var_name}"
  end

  var_file_path = File.join($home_root, @gear.uuid, '.env', var_name)

  refute_file_exist var_file_path
end

def get_app_from_hash_with_given_namespace(namespace_key)
    if @unique_namespace_apps_hash[namespace_key].nil?
      raise "Error: The namespace key \'#{namespace_key}\' does not exist in the @unique_namespace_apps_hash"
    end
    app = @unique_namespace_apps_hash[namespace_key]
    return app
end

def get_app_from_hash_of_all_test_apps(app_name_key)
    if @test_apps_hash[app_name_key].nil?
      raise "Error: The app name key \'#{app_name_key}\' does not exist in the @test_apps_hash"
    end
    app = @test_apps_hash[app_name_key]
    return app
end


def check_domain_env_var(app, actual_var_name, expected_var_name = nil, negate = false, prefix = false)
  if prefix
    var_name = "OPENSHIFT_#{actual_var_name}"
  end
  var_file_path = File.join($home_root, app.uid, '.env', actual_var_name)
  check_var_name(var_file_path, expected_var_name, negate)

end

def cart_env_var_will_exist(cart_name, var_name, negate = false)
  cart_env_var_common cart_name, var_name, nil, negate
end

def cart_env_var_will_equal(cart_name, var_name, expected)
  cart_env_var_common cart_name, var_name, expected, false
end

def cart_env_var_common(cart_name, var_name, expected = nil, negate = false)
  var_name = "OPENSHIFT_#{var_name}"

  cartridge = @gear.container.cartridge_model.get_cartridge(cart_name)

  var_file_path = File.join($home_root, @gear.uuid, cartridge.directory, 'env', var_name)
  check_var_name(var_file_path, expected, negate)

end

def check_var_name(var_file_path, expected = nil, negate = false)
  if negate
    refute_file_exist var_file_path
  else
    assert_file_exist var_file_path
    assert((File.stat(var_file_path).size > 0), "#{var_file_path} is empty")
    if expected
      file_content = File.read(var_file_path).chomp
      assert_match /#{expected}/, file_content
    end
  end

end

def commit_simple_change
  record_measure("Runtime Benchmark: Committing random change to app repo at #{@app.git_repo}") do
    Dir.chdir(@app.git_repo) do
      # Make a change to the app repo
      ENV['X_SCLS'] = nil
      run "echo $RANDOM >> cucumber_update_test"
      run "git add ."
      run "git commit -m 'Test change'"
    end
  end
end

# Used to control the runtime state of the current application.
When /^I (start|stop|status|restart|tidy|reload) the newfangled application$/ do |action|
  OpenShift::timeout(60) do
    record_measure("Runtime Benchmark: Hook #{action} on application #{@cart.name}") do
      @app.send(action)
    end
  end
end

Then /^the "(.*)" content does( not)? exist(s)? for ([^ ]+)$/ do |path, negate, _, cartridge_name|
  cartridge = @gear.container.cartridge_model.get_cartridge(cartridge_name)
  entry = File.join($home_root, @gear.uuid, path)

  if negate
    refute_file_exist entry
  else
    assert_file_exist entry
  end
end

Then /^the ([^ ]+) cartridge will support threaddump/ do |cartridge_name|
    @gear.container.threaddump(cartridge_name)
end

Then /^the ([^ ]+) cartridge instance directory will( not)? exist$/ do |cartridge_name, negate|
  cartridge = @gear.container.cartridge_model.get_cartridge(cartridge_name)

  cartridge_dir = File.join($home_root, @gear.uuid, cartridge.directory)

  if negate
    refute_directory_exist cartridge_dir
  else
    assert_directory_exist cartridge_dir
  end
end

Then /^the ([^ ]+) ([^ ]+) env entry will( not)? exist$/ do |cartridge_name, variable, negate|
  cart_env_var_will_exist(cartridge_name, variable, negate)
end

Then /^the ([^ ]+) ([^ ]+) env entry will equal '([^\']+)'$/ do |cartridge_name, variable, expected|
  cart_env_var_will_equal cartridge_name, variable, expected
end

Then /^the platform-created default environment variables will exist$/ do
  assert_app_env_var('APP_DNS')
  assert_app_env_var('APP_NAME')
  assert_app_env_var('APP_UUID')
  assert_app_env_var('DATA_DIR')
  assert_app_env_var('REPO_DIR')
  assert_app_env_var('GEAR_DNS')
  assert_app_env_var('GEAR_NAME')
  assert_app_env_var('GEAR_UUID')
  assert_app_env_var('TMP_DIR')
  assert_app_env_var('HOMEDIR')
  assert_app_env_var('HISTFILE', false)
end


Then /^the domain environment variable ([^\"]*) with value '([^\"]*)' is added in the namespace "([^\"]*)"$/ do | env_var_name, env_var_value, namespace_key|
    app = get_app_from_hash_with_given_namespace(namespace_key)
    domain = app.namespace
    app_login = app.login
    command = "oo-admin-ctl-domain -l \"#{app_login}\" -n #{domain} -c env_add -e #{env_var_name} -v #{env_var_value}"
    $logger.info("Executing the command: #{command}")
    output_buffer = []
    exit_code = run(command, output_buffer)
    raise "Error: Failed to add domain env var #{env_var_name}. Exit code: #{exit_code} and Output Message: #{output_buffer}" unless output_buffer[0] == ""
end

Then /^the domain environment variable ([^\"]*) is deleted in the namespace "([^\"]*)"$/ do | env_var_name, namespace_key|
    app = get_app_from_hash_with_given_namespace(namespace_key) 
    domain = app.namespace
    app_login = app.login
    command = "oo-admin-ctl-domain -l \"#{app_login}\" -n #{domain} -c env_del -e #{env_var_name}"
    $logger.info("Executing the command: #{command}")
    output_buffer = []
    exit_code = run(command, output_buffer)
    raise "Error: Failed to add domain env var #{env_var_name}. Exit code: #{exit_code} and Output Message: #{output_buffer}" unless output_buffer[0] == ""
end 


Then /^the domain environment variable ([^\"]*) will( not)? exist for the application "([^\"]*)"$/ do |var_name, negate, app_name_key|
    app = get_app_from_hash_of_all_test_apps(app_name_key)
    check_domain_env_var app, var_name, nil, negate
end


Then /^the domain environment variable ([^\"]*) will equal '([^\"]*)' for the application "([^\"]*)"$/ do |actual_var_name, expected_var_name, app_name_key|
    app = get_app_from_hash_of_all_test_apps(app_name_key)
    check_domain_env_var app, actual_var_name, expected_var_name, false
end

Then /^the domain environment variable ([^\"]*) will( not)? exist for all the applications in the namespace "([^\"]*)"$/ do |var_name, negate, namespace_key|
   app_with_namespace_key = get_app_from_hash_with_given_namespace(namespace_key) 
   target_namespace = app_with_namespace_key.namespace  

   if !(@test_apps_hash.nil?) 
      @test_apps_hash.each do |app_name_key, app|
         if app.namespace == target_namespace
            check_domain_env_var app, var_name, nil, negate
	 end
       end
   else
      raise "Error: Cannot check for domain env var #{var_name} because the hash of TestApps is empty"
   end

end

Then /^the domain environment variable ([^\"]*) will equal '([^\"]*)' for all the applications in the namespace "([^\"]*)"$/ do |actual_var_name, expected_var_name, namespace_key|
   app_with_namespace_key = get_app_from_hash_with_given_namespace(namespace_key)
   target_namespace = app_with_namespace_key.namespace
    if !(@test_apps_hash.nil?)
       @test_apps_hash.each do |app_name_key, app|
          if app.namespace == target_namespace
            check_domain_env_var app, actual_var_name, expected_var_name, false
          end
       end
   else
      raise "Error: Cannot check for env var #{actual_var_name} because the list of TestApps is empty"
   end
end


Then /^the ([^ ]+) cartridge private endpoints will be (exposed|concealed)$/ do |cart_name, action|
  cartridge = @gear.container.cartridge_model.get_cartridge(cart_name)

  cartridge.endpoints.each do |endpoint|
    $logger.info("Validating private endpoint #{endpoint.private_ip_name}:#{endpoint.private_port_name} "\
                 "for cartridge #{cart_name}")
    case action
    when 'exposed'
      assert_app_env_var(endpoint.private_ip_name, false)
      assert_app_env_var(endpoint.private_port_name, false)
    when 'concealed'
      refute_app_env_var(endpoint.private_ip_name, false)
      refute_app_env_var(endpoint.private_port_name, false)
    end
  end
end

Then /^the ([^ ]+) cartridge endpoints with ssl to gear option will be (exposed|concealed)$/ do |cart_name, action|
  cartridge = @gear.container.cartridge_model.get_cartridge(cart_name)

  cartridge.endpoints.each do |endpoint|
    if endpoint.options and endpoint.options["ssl_to_gear"]
      $logger.info("Validating public endpoint #{endpoint.private_ip_name}:#{endpoint.private_port_name}:"\
                   "#{endpoint.public_port_name} for cartridge #{cart_name}")
      case action
      when 'exposed'
        assert_app_env_var(endpoint.public_port_name, false)
      when 'concealed'
        refute_app_env_var(endpoint.public_port_name, false)
      end
    end
  end
end

Then /^the application state will be ([^ ]+)$/ do |state_value|
  state_const = OpenShift::Runtime::State.const_get(state_value.upcase)

  raise "Invalid state '#{state_value}' provided to step" unless state_const

  assert_equal @gear.container.state.value, state_const
end

Then /^the ([^ ]+) cartridge status should be (running|stopped)$/ do |cart_name, expected_status|
  begin
    @gear.carts[cart_name].status
    # If we're here, the cart status is 'running'
    raise "Expected #{cart_name} cartridge to be stopped" if expected_status == "stopped"
  rescue OpenShift::Runtime::Utils::ShellExecutionException
    # If we're here, the cart status is 'stopped'
    raise if expected_status == "running"
  end
end

Then /^the application stoplock should( not)? be present$/ do |negate|
  stop_lock = File.join($home_root, @gear.uuid, 'app-root', 'runtime', '.stop_lock')

  if negate
    refute_file_exist stop_lock
  else
    assert_file_exist stop_lock
  end 
end

When /^the application hot deploy marker is (added|removed)$/ do |verb|
  record_measure("Runtime Benchmark: #{verb} hot deploy marker app repo at #{@app.git_repo}") do
    Dir.chdir(@app.git_repo) do
      if verb == "added"
        run "mkdir -p .openshift/markers && touch .openshift/markers/hot_deploy"
        run "git add ."
      else
        run "git rm .openshift/markers/hot_deploy"
      end

      run "git commit -m '#{verb} hot deploy marker'"
      push_output = `git push`
      $logger.info("Push output:\n#{push_output}")
    end
  end
end

Then /^I can run "([^\"]*)" with exit code: (\d+)$/ do |cmd, code|
  command = ssh_command("rhcsh #{cmd}")
  
  $logger.debug "Running #{command}"

  output = `#{command}`

  $logger.debug "Output: #{output}"

  assert_equal code.to_i, $?.exitstatus
end

When /^I run the rhcsh command "([^\"]*)"$/ do |cmd|
  command = ssh_command("rhcsh #{cmd}")

  $logger.debug "Running #{command}"

  output = `#{command}`

  $logger.debug "Output: #{output}"
end

When /^I tail the logs via ssh$/ do
  ssh_cmd = ssh_command("tail -f */logs/\\*")
  stdout, stdin, pid = PTY.spawn ssh_cmd

  @ssh_cmd = {
    :pid => pid,
    :stdin => stdin,
    :stdout => stdout,
  }
end

When /^I stop tailing the logs$/ do
  begin
    Process.kill('KILL', @ssh_cmd[:pid])
    exit_code = -1

    # Don't let a command run more than 1 minute
    Timeout::timeout(60) do
      ignored, status = Process::waitpid2 @ssh_cmd[:pid]
      exit_code = status.exitstatus
    end
  rescue PTY::ChildExited
    # Completed as expected
  end
end

Then /^I can obtain disk quota information via SSH$/ do
  cmd = ssh_command('/usr/bin/quota')

  $logger.debug "Running: #{cmd}"

  out = `#{cmd}`

  $logger.debug "Output: #{out}"

  if out.index("Disk quotas for user ").nil?
    raise "Could not obtain disk quota information"
  end  
end

When /^I (start|stop) the application using ctl_all via rhcsh$/ do |action|
  cmd = case action
  when 'start'
    ssh_command("rhcsh ctl_all start")
  when 'stop'
    ssh_command("rhcsh ctl_all stop")
  end

  $logger.debug "Running #{cmd}"

  output = `#{cmd}`

  $logger.debug "Output: #{output}"
end

Then /^the Apache nodes DB file will contain ([^ ]+) for the ssl_to_gear endpoint$/ do |option|
  file = File.join($home_root,".httpd.d","nodes.txt")
  assert_file_exist file
  option_found = false
  File.read(file).each_line do |line|
    if line[/#{@app.name}[^ ]+\s#{option}/]
      option_found = true
      line.match(/#{option}:([0-9\.]+):([0-9]+)/) do |match|
        assert_equal match[1], File.read(File.join($home_root,@app.uid,".env","OPENSHIFT_HAPROXY_IP"))
        assert_equal match[2], File.read(File.join($home_root,@app.uid,".env","OPENSHIFT_HAPROXY_PORT"))
      end
    end
  end
  assert option_found
end

Then /^the haproxy.cfg file will( not)? be configured to proxy SSL to the backend gear$/ do |negate|
  file = File.join($home_root,@app.uid,"haproxy","conf","haproxy.cfg")
  assert_file_exist file
  content = File.read(file)
  assert_not_nil content.match(/mode tcp\n/)
  assert_not_nil content.match(/option ssl-hello-chk\n/)
  assert_not_nil content.match(/option tcplog\n/)
end

When /^I send an (https?) request to the app( on port (\d+))?$/ do |protocol, onport, port|
  urlstr = "#{protocol}://#{@app.name}-#{@app.namespace}.dev.rhcloud.com"
  if port and (port.to_i > 0)
    urlstr += ":#{port.to_i}"
  end
  # httpclient set to TLSv1 is required for SNI support
  http = HTTPClient.new()
  http.ssl_config.verify_mode=OpenSSL::SSL::VERIFY_NONE
  http.ssl_config.ssl_version="TLSv1"
  @response = http.get(urlstr)
end

Then /^It will return ([^ ]+)($|\s.*)$/ do |check, value|
  if check == "redirect"
    assert_equal "https://#{@app.hostname}", @response.header["location"].first
  elsif check == "content"
    assert value, @response.body
  end
end
