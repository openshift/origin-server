# Support steps for runtime-centric tests.
#
# IMPORTANT: The steps defined here are for basic sanity checks of a 
# SINGLE application with a SINGLE gear and cartridge, and all work 
# in the context of these assumptions. If your test needs more complex 
# setups, write some more steps which are more flexible.

require 'fileutils'

# These are provided to reduce duplication of code in feature files.
#   Scenario Outlines are not used as they interfer with the devenv retry logic (whole feature is retried no example line)
Given /^a new ([^ ]+) application, verify it using ([^ ]+)$/ do |cart_name, proc_name|
  steps %Q{
    Given a new #{cart_name} type application
    Then the application http proxy file will exist
    And a #{proc_name} process will be running
    And the application git repo will exist
    And the application source tree will exist
    And the application log files will exist
    When I stop the application
    Then a #{proc_name} process will not be running
    When I start the application
    Then a #{proc_name} process will be running
    When I status the application
    Then a #{proc_name} process will be running
    When I restart the application
    Then a #{proc_name} process will be running
    When I destroy the application
    Then the application http proxy file will not exist
    And a #{proc_name} process will not be running
    And the application git repo will not exist
    And the application source tree will not exist
  }
end

Given /^a new ([^ ]+) application, verify create and delete using ([^ ]+)$/ do |cart_name, proc_name|
  steps %Q{
    Given a new #{cart_name} type application
    Then the application http proxy file will exist
    And a #{proc_name} process will be running
    And the application git repo will exist
    And the application source tree will exist
    And the application log files will exist
    When I destroy the application
    Then the application http proxy file will not exist
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
    Then the application http proxy file will not exist
    And a #{proc_name} process will not be running
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
      assert_raise(OpenShift::Utils::ShellExecutionException) do
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
    raise "No embedded cart named #{cart_name} associated with gear #{gear.uuid}" unless @gear.carts.has_key?(cart_name)

    embedded_cart = @gear.carts[cart_name]

    embedded_cart.deconfigure
  end
end


# Verifies the existence of httpd proxy files associated with
# the current application.
Then /^the application http proxy file will( not)? exist$/ do | negate |
  conf_file_name = "#{@gear.uuid}_#{@account.domain}_#{@app.name}.conf"
  conf_file_path = "#{$libra_httpd_conf_d}/#{conf_file_name}"

  $logger.info("Checking for #{negate} proxy file at #{conf_file_path}")
  if negate
    assert_file_not_exists conf_file_path
  else
    assert_file_exists conf_file_path
  end
end


# Verifies the existence of an httpd proxy file for the given embedded
# cartridge associated with the current application.
Then /^the embedded ([^ ]+) cartridge http proxy file will( not)? exist$/ do | cart_name, negate |
  conf_file_name = "#{@gear.uuid}_#{@account.domain}_#{@app.name}/#{cart_name}.conf"
  conf_file_path = "#{$libra_httpd_conf_d}/#{conf_file_name}"

  $logger.info("Checking for #{negate} embedded cartridge proxy file at #{conf_file_path}")
  if negate
    assert_file_not_exists conf_file_path
  else
    assert_file_exists conf_file_path
  end
end


# Verifies the existence of a git repo associated with the current
# application.
Then /^the application git repo will( not)? exist$/ do | negate |
  git_repo = "#{$home_root}/#{@gear.uuid}/git/#{@app.name}.git"

  # TODO - need to check permissions and SELinux labels

  $logger.info("Checking for #{negate} git repo at #{git_repo}")
  if negate
    assert_directory_not_exists git_repo
  else
    assert_directory_exists git_repo
  end
end


# Verifies the existence of an exported source tree associated with
# the current application.
Then /^the application source tree will( not)? exist$/ do | negate |
  app_root = "#{$home_root}/#{@gear.uuid}/#{@cart.name}"

  # TODO - need to check permissions and SELinux labels

  $logger.info("Checking for app root at #{app_root}")
  if negate
    assert_directory_not_exists app_root
  else
    assert_directory_exists app_root
  end
end


# Verifies the existence of application log files associated with the
# current application.
Then /^the application log files will( not)? exist$/ do | negate |
  log_dir_path = "#{$home_root}/#{@gear.uuid}/#{@cart.name}/logs"

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
  user_root = "#{$home_root}/#{@gear.uuid}/#{cart_name}"

  $logger.info("Checking for #{negate} cartridge root dir at #{user_root}")
  if negate
    assert_directory_not_exists user_root
  else
    assert_directory_exists user_root
  end
end


# Ensures that more than zero log files exist in the given embedded cartridge
# log directory.
Then /^the embedded ([^ ]+) cartridge log files will( not)? exist$/ do | cart_name, negate |
  log_dir_path = "#{$home_root}/#{@gear.uuid}/#{cart_name}/logs"

  $logger.info("Checking for #{negate} cartridge log dir at #{log_dir_path}")
  if negate
    assert_directory_not_exists log_dir_path
  else
    assert_directory_exists log_dir_path
  end
end


# Simple verification of arbitrary cartridge directory existence.
Then /^the embedded ([^ ]+) cartridge subdirectory named ([^ ]+) will( not)? exist$/ do | cart_name, dir_name, negate |
  dir_path = "#{$home_root}/#{@gear.uuid}/#{cart_name}/#{dir_name}"

  $logger.info("Checking for #{negate} cartridge subdirectory at #{dir_path}")
  if negate
    assert_directory_not_exists dir_path
  else
    assert_directory_exists dir_path
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
    assert_file_not_exists startup_file
  else
    assert_file_exists startup_file
  end
end


# Used to control the runtime state of the current application.
#
# IMPORTANT: As mentioned in the general comments, this step assumes
# a single application/gear/cartridge, and does its work by controlling
# the single cartridge directly. There will be no recursive actions for
# multiple carts associated with an app/gear.
When /^I (start|stop|status|restart) the application$/ do |action|
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
  run "echo \"127.0.0.1 #{@app.name}-#{@account.domain}.dev.rhcloud.com # Added by cucumber\" >> /etc/hosts"
  run "oo-authorized-ssh-key-add -a #{@gear.uuid} -c #{@gear.uuid} -s #{ssh_key} -t ssh-rsa -m default"
  run "echo -e \"Host #{@app.name}-#{@account.domain}.dev.rhcloud.com\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config"
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


# Performs a trivial update to the test application source by appending
# some random stuff to a dummy file. The change is then committed and 
# pushed to the app's Git repo.
When /^an update (is|has been) pushed to the application repo$/ do |junk|
  record_measure("Runtime Benchmark: Updating #{$temp}/#{@account.name}-#{@app.name} source") do
    tmp_git_root = "#{$temp}/#{@account.name}-#{@app.name}-clone"

    run "git clone ssh://#{@gear.uuid}@#{@app.name}-#{@account.domain}.dev.rhcloud.com/~/git/#{@app.name}.git #{tmp_git_root}"

    marker_file = File.join(tmp_git_root, '.openshift', 'markers', 'hot_deploy')

    if @app.hot_deploy_enabled
      FileUtils.touch(marker_file)
    else
      FileUtils.rm_f(marker_file)
    end

    Dir.chdir(tmp_git_root) do
      # Make a change to the app repo
      run "echo $RANDOM >> cucumber_update_test"
      run "git add ."
      run "git commit -m 'Test change'"
      run "git push"
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
  conf_file = File.join($libra_httpd_conf_d,
                       "#{@gear.uuid}_#{@account.domain}_#{@app.name}",
                       "#{cart_type}-#{version}.conf")

  # The URL segment for the cart lives in the proxy conf
  cart_path = `/bin/awk '/ProxyPassReverse/ {printf "%s", $2;}' #{conf_file}`
  url = "https://127.0.0.1#{cart_path}#{uri}"

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
