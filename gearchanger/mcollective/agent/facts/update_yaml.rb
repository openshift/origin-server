#!/bin/env ruby

require 'facter'
require 'yaml'

def single_instance(&block)
  if File.open($0).flock(File::LOCK_EX|File::LOCK_NB)
    block.call
  else
    warn "Script #{ $0 } is already running"
  end
end

single_instance do
  puts YAML.dump(Facter.to_hash)
end
