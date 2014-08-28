require 'rubygems'
require 'uri'
require 'fileutils'

include AppHelper

Then /^the logs should contain (.+)$/ do |msg|
  for i in 0..20
    count=@app.ssh_command("\\$OPENSHIFT_FUSE_DIR/container/bin/client log:display | grep \"#{msg}\" | wc -l")
    break if(count.to_i>0) 
    sleep 10
  end
  count.to_i.should > 0
end
