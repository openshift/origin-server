#!/bin/env oo-ruby
require 'facter'
require 'yaml'
require 'tempfile'
require 'fileutils'

out_file = ARGV[0]

def single_instance(&block)
  if File.open($0).flock(File::LOCK_EX|File::LOCK_NB)
    block.call
  else
    warn "Script #{ $0 } is already running"
  end
end

single_instance do
  tmp_file = Tempfile.new(File.basename(out_file))
  begin
    tmp_file.write(Facter.to_hash.to_yaml)
  ensure
    tmp_file.close
  end

  FileUtils.mv(tmp_file.path, out_file, :force => true)
  %x[ /sbin/restorecon #{out_file} ]
end
