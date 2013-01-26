#!/usr/bin/env ruby
require 'webrick'
include WEBrick

config = {}
config.update(:Port => 8080)
config.update(:BindAddress => ENV['OPENSHIFT_INTERNAL_IP'])
config.update(:DocumentRoot => ENV['OPENSHIFT_REPO_DIR'] + "/pod")
server = HTTPServer.new(config)
['INT', 'TERM'].each {|signal|
  trap(signal) {server.shutdown}
}

server.start
