require 'fileutils'
require 'logger'
require 'etc'

#
# Define global variables
#
$temp = "/tmp/rhc"

$client_config = "/etc/openshift/express.conf"

 
# Use the domain from the rails application configuration
$domain = "example.com"

# Set the dns helper module
$dns_helper_module = File.dirname(__FILE__) + "/dns_helper.rb"

# oddjob service name and selinux context (specify nil if no alternate context is being used)
$gear_update_plugin_service = "oddjobd"
$selinux_user = nil
$selinux_role = nil
$selinux_type = nil

# User registration flag and script
$registration_required = true
$user_register_script_format = "/usr/bin/ss-register-user -l admin -p admin --username %s --userpass %s"

# Alternatie domain suffix for use in alias commands
$alias_domain = "foobar.com"

# Submodule repo directory for testing submodule addition test case
$submodule_repo_dir = "#{Etc.getpwuid.dir}/submodule_test_repo"

#
# Old RHC Client scripts
#
$create_app_script = "/usr/bin/rhc-create-app"
$create_domain_script = "/usr/bin/rhc-create-domain"
$ctl_app_script = "/usr/bin/rhc-ctl-app"
$user_info_script = "/usr/bin/rhc-domain-info"
$snapshot_script = "/usr/bin/rhc-snapshot"

#
# New RHC Client scripts
#
$rhc_app_script = "/usr/bin/rhc-app"
$rhc_domain_script = "/usr/bin/rhc-domain"
$rhc_sshkey_script = "/usr/bin/rhc-sshkey"

# RSA Key constants
$test_pub_key = File.expand_path("~/.ssh/id_rsa.pub")
$test_priv_key = File.expand_path("~/.ssh/id_rsa")

module SetupHelper
  def self.setup
    # Create the temporary space
    FileUtils.mkdir_p $temp

    # Remove all temporary data
    #FileUtils.rm_rf Dir.glob(File.join($temp, "*"))
    
    # Setup the logger
    $logger = Logger.new(File.join($temp, "cucumber.log"))
    $logger.level = Logger::DEBUG
    $logger.formatter = proc do |severity, datetime, progname, msg|
        "#{$$} #{severity} #{datetime}: #{msg}\n"
    end

    # Setup performance monitor logger
    $perfmon_logger = Logger.new(File.join($temp, "perfmon.log"))
    $perfmon_logger.level = Logger::INFO
    $perfmon_logger.formatter = proc do |severity, datetime, progname, msg|
        "#{$$} #{datetime}: #{msg}\n"
    end

    # If the default ssh key is not present, create one
    `ssh-keygen -q -f #{$test_priv_key} -P ''` if !File.exists?($test_priv_key)
    FileUtils.chmod 0600, $test_priv_key

    # create a submodule repo for the tests
    if !File.exists?($submodule_repo_dir)
      `git init #{$submodule_repo_dir}`
      Dir.chdir($submodule_repo_dir) do
        `echo Submodule > index`
        `git add index`
        `git commit -m 'test'`
      end
    end

  end
end
World(SetupHelper)
