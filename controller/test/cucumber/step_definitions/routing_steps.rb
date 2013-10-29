require 'rubygems'
require 'uri'
require 'fileutils'
require 'json'
require 'pty'
require 'test/unit'

include AppHelper
include Test::Unit::Assertions

When /^the http host header is overridden with a valid host, ensure routing succeeds$/ do
  output = []
  IO.popen("curl -s -w %{http_code} -k -H 'X-OpenShift-Host: #{@app.name}-#{@app.namespace}.#{$cloud_domain}' https://#{@app.name}-#{@app.namespace}.#{$cloud_domain} -o /dev/null | grep 200").each do |line|
    p line.chomp
    output << line.chomp
  end

  output[0].to_i.should == 200
end

When /^the http host header is overridden with an invalid host, ensure routing fails$/ do
  output = []
  IO.popen("curl -s -w %{http_code} -k -H 'X-OpenShift-Host: blarg-#{@app.namespace}.#{$cloud_domain}' https://#{@app.name}-#{@app.namespace}.#{$cloud_domain} -o /dev/null | grep 302").each do |line|
    p line.chomp
    output << line.chomp
  end

  output[0].to_i.should == 302
end
