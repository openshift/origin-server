#!/usr/bin/env oo-ruby

require 'rubygems'
require 'time'
require "/var/www/openshift/broker/config/environment"

$user_count = 0
$t = Time.new(2013,9,17)


def clean_user(u)
  $user_count += 1
  u.reload
  dlist = u.pending_ops.select { |op| (op.created_at.nil? or op.created_at < $t) }
  puts "Cleaning #{dlist.length} ops from user #{u._id.to_s}"
  dlist.each { |op| op.delete }
end

CloudUser.no_timeout.lt("pending_ops.created_at" => $t).each { |u| 
  begin
    print "."
    clean_user(u)
  rescue Exception=>e
    puts e.message
    puts e.backtrace
  end
}

puts "#{$user_count} users were cleaned up"
exit 0
