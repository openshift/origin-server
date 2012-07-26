# Support steps for runtime-centric tests.
#
# IMPORTANT: The steps defined here are for basic sanity checks of a 
# SINGLE application with a SINGLE gear and cartridge, and all work 
# in the context of these assumptions. If your test needs more complex 
# setups, write some more steps which are more flexible.

require 'fileutils'

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
Given /^a new ([^ ]+) type application$/ do | cart_name |
  @account = StickShift::TestAccount.new

  @app = @account.create_app
  @gear = @app.create_gear
  @cart = @gear.add_cartridge(cart_name)

  @cart.configure
end


# Invokes destroy on the current application.
When /^I destroy the application$/ do
  @app.destroy
end


# Embeds a new cartridge to the current application's gear, and calls
# configure on the cartridge.
When /^I embed a ([^ ]+) cartridge into the application$/ do | cart_name |
  $logger.info("Adding an embedded #{cart_name} cartridge to application #{@app.name}")
  cart = @gear.add_cartridge(cart_name, StickShift::TestCartridge::Embedded)
  cart.configure
end


# Verifies the existence of httpd proxy files associated with
# the current application.
Then /^the application http proxy file will( not)? exist$/ do | negate |
  conf_file_name = "#{@gear.uuid}_#{@account.domain}_#{@app.name}.conf"
  conf_file_path = "#{$libra_httpd_conf_d}/#{conf_file_name}"

  $logger.info("Checking for proxy file at #{conf_file_path}")

  if not negate
    File.exists?(conf_file_path).should be_true
  else
    File.exists?(conf_file_path).should be_false
  end
end


# Verifies the existence of an httpd proxy file for the given embedded
# cartridge associated with the current application.
Then /^the embedded ([^ ]+) cartridge http proxy file will( not)? exist$/ do | cart_name, negate |
  conf_file_name = "#{@gear.uuid}_#{@account.domain}_#{@app.name}/#{cart_name}.conf"
  conf_file_path = "#{$libra_httpd_conf_d}/#{conf_file_name}"

  $logger.info("Checking for embedded cartridge proxy file at #{conf_file_path}")

  if not negate
    File.exists?(conf_file_path).should be_true
  else
    File.exists?(conf_file_path).should be_false
  end
end


# Verifies the existence of a git repo associated with the current
# application.
Then /^the application git repo will( not)? exist$/ do | negate |
  git_repo = "#{$home_root}/#{@gear.uuid}/git/#{@app.name}.git"
  status = (File.exists? git_repo and File.directory? git_repo)
  # TODO - need to check permissions and SELinux labels

  $logger.info("Checking for git repo at #{git_repo}")

  if not negate
    status.should be_true
  else
    status.should be_false
  end

end


# Verifies the existence of an exported source tree associated with
# the current application.
Then /^the application source tree will( not)? exist$/ do | negate |
  app_root = "#{$home_root}/#{@gear.uuid}/#{@app.name}"
  status = (File.exists? app_root and File.directory? app_root) 
  # TODO - need to check permissions and SELinux labels

  $logger.info("Checking for app root at #{app_root}")

  if not negate
    status.should be_true
  else
    status.should be_false
  end

end


# Verifies the existence of application log files associated with the
# current application.
Then /^the application log files will( not)? exist$/ do | negate |
  log_dir_path = "#{$home_root}/#{@gear.uuid}/#{@app.name}/logs"

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

  $logger.info("Checking for cartridge root dir at #{user_root}")
  begin
    cart_dir = Dir.new user_root
  rescue Errno::ENOENT
    cart_dir = nil
  end

  unless negate
    cart_dir.should be_a(Dir)
  else
    cart_dir.should be_nil
  end
end


# Ensures that more than zero log files exist in the given embedded cartridge
# log directory.
Then /^the embedded ([^ ]+) cartridge log files will( not)? exist$/ do | cart_name, negate |
  log_dir_path = "#{$home_root}/#{@gear.uuid}/#{cart_name}/logs"

  $logger.info("Checking for cartridge log dir at #{log_dir_path}")
  begin
    log_dir = Dir.new log_dir_path
    status = (log_dir.count > 0)
  rescue
    status = false
  end

  if not negate
    status.should be_true
  else
    status.should be_false
  end
end


# Simple verification of arbitrary cartridge directory existence.
Then /^the embedded ([^ ]+) cartridge subdirectory named ([^ ]+) will( not)? exist$/ do | cart_name, dir_name, negate |
  dir_path = "#{$home_root}/#{@gear.uuid}/#{cart_name}/#{dir_name}"

  $logger.info("Checking for cartridge subdirectory at #{dir_path}")
  begin
    log_dir = Dir.new dir_path
    status = true
  rescue
    status = false
  end

  if not negate
    status.should be_true
  else
    status.should be_false
  end
end


# Ensures that the named control script exists for the given embedded cartridge of the
# current application.
Then /^the embedded ([^ ]+) cartridge control script named ([^ ]+) will( not)? exist$/ do |cart_name, script_name, negate|
  user_root = "#{$home_root}/#{@gear.uuid}/#{cart_name}"
  startup_file = "#{user_root}/#{@app.name}_#{script_name}_ctl.sh"

  $logger.info("Checking for cartridge control script at #{startup_file}")

  begin
    startfile = File.new startup_file
  rescue Errno::ENOENT
    startfile = nil
  end

  unless negate
    startfile.should be_a(File)
  else
    startfile.should be_nil
  end
end


# Used to control the runtime state of the current application.
#
# IMPORTANT: As mentioned in the general comments, this step assumes
# a single application/gear/cartridge, and does its work by controlling
# the single cartridge directly. There will be no recursive actions for
# multiple carts associated with an app/gear.
When /^I (start|stop|status|restart) the application$/ do |action|
  @cart.run_hook(action)
end


# Controls carts within the current gear directly, by cartridge name.
# The same comments from the similar matcher apply.
When /^I (start|stop|status|restart) the ([^ ]+) cartridge$/ do |action, cart_name|
  @gear.carts[cart_name].run_hook(action)
end


# Verifies that a process named proc_name and associated with the current
# application will be running (or not). The step will retry up to max_tries
# times to verify the expectations, as some cartridge stop hooks are
# asynchronous. This doesn't outright eliminate timing issues, but it helps.
Then /^a (.+) process will( not)? be running$/ do | proc_name, negate |
  max_tries = 7
  poll_rate = 3
  exit_test = negate ? lambda { |tval| tval == 0 } : lambda { |tval| tval > 0 }
  exit_test_desc = negate ? "0" : ">0"
 
  tries = 0
  num_node_processes = num_procs @gear.uuid, proc_name

  $logger.info("Expecting #{exit_test_desc} pid(s) named #{proc_name}, found #{num_node_processes}")
  while (not exit_test.call(num_node_processes) and tries < max_tries)
    tries += 1
    
    $logger.info("Waiting #{poll_rate}s for #{proc_name} process count to be #{exit_test_desc} (retry #{tries} of #{max_tries})")

    sleep poll_rate

    num_node_processes = num_procs @gear.uuid, proc_name
  end

  if not negate
    num_node_processes.should be > 0
  else
    num_node_processes.should be == 0
  end
end


# Verifies that exactly the specified number of the named processed
# are currently running.
#
# Could maybe be consolidated with the other similar step with some
# good refactoring.
Then /^(\d+) process(es)? named ([^ ]+) will be running$/ do | proc_count, junk, proc_name |
  proc_count = proc_count.to_i

  max_tries = 7
  poll_rate = 3
  
  tries = 0
  num_node_processes = num_procs @gear.uuid, proc_name

  $logger.info("Expecting #{proc_count} pid(s) named #{proc_name}, found #{num_node_processes}")
  while (num_node_processes != proc_count and tries < max_tries)
    tries += 1
    
    $logger.info("Waiting #{poll_rate}s for #{proc_name} process count to equal #{proc_count} (retry #{tries} of #{max_tries})")

    sleep poll_rate

    num_node_processes = num_procs @gear.uuid, proc_name
  end
  
  num_node_processes.should be == proc_count
end


# Performs some hackery to enable git pushes to the test application
# repo, such as:
#
#   - Adding an /etc/hosts entry for the application to work around
#     the lack of DNS
#   - Adds the test pubkey to the authorized key list for the host
#   - Disables strict host key checking for the host to suppress
#     interactive prompts on push
#
# This is not pretty. If it can be made less hackish and faster, it
# could be moved into the generic application setup step.
When /^the application is prepared for git pushes$/ do
  ssh_key = IO.read($test_pub_key).chomp.split[1]
  run "echo \"127.0.0.1 #{@app.name}-#{@account.domain}.dev.rhcloud.com # Added by cucumber\" >> /etc/hosts"
  run "ss-authorized-ssh-key-add -a #{@gear.uuid} -c #{@gear.uuid} -s #{ssh_key} -t ssh-rsa -m default"
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
When /^an update is pushed to the application repo$/ do
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
end
