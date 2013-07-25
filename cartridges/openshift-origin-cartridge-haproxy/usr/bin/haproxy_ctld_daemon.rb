#!/usr/bin/env oo-ruby

require 'rubygems'
require 'daemons'
require 'fileutils'

options = {
    :backtrace => true,
    :ontop => false,
    :log_output => true,
    :log_dir => "#{ENV['OPENSHIFT_HAPROXY_LOG_DIR']}",
    :log_output => true,
    :dir_mode => :normal,
    :dir => "#{ENV['OPENSHIFT_HAPROXY_DIR']}/run",
    :multiple => false,
    
}

FileUtils.touch("#{ENV['OPENSHIFT_HAPROXY_LOG_DIR']}/validate_config.log")
FileUtils.touch("#{ENV['OPENSHIFT_HAPROXY_LOG_DIR']}/scale_events.log")
Daemons.run("#{ENV['OPENSHIFT_HAPROXY_DIR']}/usr/bin/haproxy_ctld.rb", options)
