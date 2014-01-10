#!/usr/bin/env oo-ruby

require 'rubygems'
require 'daemons'
require 'fileutils'

options = {
    :backtrace => true,
    :ontop => false,
    :log_output => true,
    :log_dir => ENV['OPENSHIFT_HAPROXY_LOG_DIR'],
    :dir_mode => :normal,
    :dir => "#{ENV['OPENSHIFT_HAPROXY_DIR']}/run",
    :multiple => false
}

FileUtils.touch("#{ENV['OPENSHIFT_HAPROXY_LOG_DIR']}/validate_config.log")
FileUtils.touch("#{ENV['OPENSHIFT_HAPROXY_LOG_DIR']}/scale_events.log")
# If customized haproxy_ctld.rb exists, run it.
if File.exist?("#{ENV['OPENSHIFT_REPO_DIR']}/.openshift/action_hooks/haproxy_ctld.rb") and File.executable?("#{ENV['OPENSHIFT_REPO_DIR']}/.openshift/action_hooks/haproxy_ctld.rb")
    Daemons.run("#{ENV['OPENSHIFT_REPO_DIR']}/.openshift/action_hooks/haproxy_ctld.rb", options)
else
    Daemons.run("#{ENV['OPENSHIFT_HAPROXY_DIR']}/usr/bin/haproxy_ctld.rb", options)
end
