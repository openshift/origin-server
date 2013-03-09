#!/usr/bin/env oo-ruby

require 'rubygems'
require 'daemons'
#require 'openshift-origin-node'

cartridge_type = "haproxy-1.4"

options = {
    :backgrace => true,
    :ontop => false,
    :log_output => true,
    :log_dir => "#{ENV['OPENSHIFT_HAPROXY_LOG_DIR']}",
    :log_output => true,
    :dir_mode => :normal,
    :dir => "#{ENV['OPENSHIFT_HOMEDIR']}/#{cartridge_type}/run",
    :multiple => false,
    
}
#config = OpenShift::Config.instance

Daemons.run('/usr/libexec/openshift/cartridges/haproxy-1.4/info/bin/haproxy_ctld.rb', options)
