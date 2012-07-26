#!/bin/env ruby
require 'facter'
require 'yaml'

out_file = ARGV[0]

def single_instance(&block)
  if File.open($0).flock(File::LOCK_EX|File::LOCK_NB)
    block.call
  else
    warn "Script #{ $0 } is already running"
  end
end

single_instance do
  File.open(out_file, 'w') do |f|
    f.write(Facter.to_hash.to_yaml)
  end
end
