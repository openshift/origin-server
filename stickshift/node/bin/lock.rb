#!/usr/bin/ruby

require 'etc'
require 'erb'
require 'fileutils'

@UUID = ARGV[0]
@CART_TYPE = ARGV[1]

unless ARGV.count == 2
  puts "bad argv count"
  exit 3
end

# Setup Needed Variables
@HOME = File.expand_path("~#{@UUID}")
@CART_HOME = "#{@HOME}/#{@CART_TYPE}/"

Dir.chdir(@HOME)

File.open("#{@CART_HOME}/metadata/root_files.txt", 'r').each_line do | path |
  path = path.strip
  abs_path = File.expand_path(path)
  Dir.glob(abs_path).each do | file_path |
    FileUtils.chown('root', 'root', file_path)
    puts "Locking #{File.expand_path(file_path)}"
  end
end
