#!/usr/bin/env ruby
require 'webrick'
require 'webrick/https'
include WEBrick

config = {}
config.update(:BindAddress => ARGV[0])
config.update(:DocumentRoot => ARGV[1])
config.update(:Port => 8080)
if ENV["SSL_TO_GEAR"]
  cert_name = [
      %W[CN #{WEBrick::Utils::getservername}],
  ]
  config.update(:SSLEnable => true)
  config.update(:SSLCertName => cert_name)
end
server = HTTPServer.new(config)
['INT', 'TERM'].each {|signal|
  trap(signal) {server.shutdown}
}
server.start