require 'rubygems'
require 'stringio'

conf_dir = ENV['OPENSHIFT_CONF_DIR'] || '/etc/openshift'
unless ENV["RAILS_ENV"] == "test"
  ENV["RAILS_ENV"] = File.exist?(conf_dir+'/development') ? "development" : "production"
end

# Set up gems listed in the Gemfile.
gem_file = ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

# we have to jump through some hoops to intercept Bundler errors
captured = StringIO.new
save_err, save_out, $stderr, $stdout = $stderr, $stdout, captured, captured
begin
  require 'bundler/setup' if File.exist?(gem_file)
rescue Exception # Bundler calls system.exit
  $stderr, $stdout = save_err, save_out
  puts "Error while loading gems for the broker:"
  # show whatever error occurred, without any "bundle install" recommendation
  puts captured.string.split(/\n/).reject {|line| line.match(/bundle install/)}
  captured.string.match(/Could not find gem '(\S+)/) do
    # typically means a plugin or RPM is outright missing
    name = $1
    prefix = name.start_with?('openshift-origin') ? "rubygem-"
           : ENV['PATH'].match(/ruby193/)         ? "ruby193-rubygem-" : "rubygem-"
    puts "You may need to install the #{prefix + name} RPM."
    if name.start_with?('openshift-origin')
      puts "Or, you may need to remove/rename the #{name} conf file(s) in #{conf_dir}/plugins.d"
    end
  end
  captured.string.match(/Could not find (\S+) in any of the sources/) do
    # means a version mismatch with Gemfile.lock
    puts "This usually means gem RPMs have been updated and Gemfile.lock is stale."
    puts "Please restart the openshift-broker service to update it, and try again."
    # They could just delete Gemfile.lock, but if root regenerates it instead of
    # httpd, then the next time an update is needed, httpd won't be able to.
  end
  raise # we really do not want to proceed, just reword the error
ensure
  $stderr, $stdout = save_err, save_out
end
