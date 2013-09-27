#!/usr/bin/env ruby
require 'webrick'
require 'webrick/https'
include WEBrick

config = {}
cert_name = [["CN",`hostname`.strip]]
config.update(:Port => 8080)
config.update(:BindAddress => ARGV[0])
config.update(:DocumentRoot => ARGV[1])
httpserver = HTTPServer.new(config)
config.update(:SSLEnable => true)
config.update(:SSLCertName => cert_name)
config.update(:Port => 8123)
httpsserver = HTTPServer.new(config)
['INT', 'TERM'].each {|signal|
  trap(signal) do
    httpserver.shutdown
    httpsserver.shutdown
  end
}
s1 = Thread.new{
  httpserver.start
}
s2 = Thread.new{
  httpsserver.start
}

s1.join
s2.join