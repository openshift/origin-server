#!/usr/bin/env oo-ruby

require 'rubygems'
require 'daemons'

options = {
    :backgrace => true,
    :ontop => false,
    :log_output => true,
    :log_dir => "#{ENV['OPENSHIFT_HAPROXY_LOG_DIR']}",
    :log_output => true,
    :dir_mode => :normal,
    :dir => "#{ENV['OPENSHIFT_HAPROXY_DIR']}/run",
    :multiple => false,
    
}

Daemons.run("#{ENV['OPENSHIFT_HAPROXY_DIR']}/usr/bin/haproxy_ctld.rb", options)
