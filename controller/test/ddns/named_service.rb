#!/usr/bin/env oo-ruby
#
# Control a BIND DNS service for testing
#


require 'rubygems'
require 'open4'
require 'ftools' # adds File.cp
require 'fileutils' # for change directory

require 'dnsruby'

named_dir = File.dirname(__FILE__)

class BindTestService

  attr_reader :testroot, :pid
  def initialize(testroot=named_dir)

    @testroot = testroot

    # get server, port, keyname, keyvalue, zone, domain_suffix
    reset
  end

  def clean
    begin
      cwd = FileUtils.pwd
      FileUtils.cd @testroot

      # delete all journal files
      `rm -f tmp/*.jnl`

      # delete the dynamic managed keys file
      if File.exists? 'tmp/managed-keys.bind'
        File.delete 'tmp/managed-keys.bind'
      end

    ensure
      FileUtils.cd cwd
    end
  end

  def reset
    clean
    begin
      cwd = FileUtils.pwd
      FileUtils.cd @testroot

      # copy the initial example.db in place
      File.copy("example.com.db.init", "tmp/example.com.db")
      File.copy("1.168.192-rev.db.init", "tmp/1.168.192-rev.db")

    ensure
      FileUtils.cd cwd
    end
  end

  # start the daemon
  def start

    if @pid != nil
      raise "I think a named is already running with PID #{@pid}"
    end

    begin
      cwd = FileUtils.pwd
      FileUtils.cd @testroot

      begin
        pid, stdin, stdout, stderr = Open4::popen4 "/usr/sbin/named -c named.conf"
     
        # Need to check if there already is one

        stdin.close
        stdout.close
        stderr.close

        sleep 2
        @pid = File.open("tmp/named.pid").read.to_i
      ensure
        FileUtils.cd cwd
      end
    end
  end

  def stop
    if @pid == nil
      raise "no PID: is there really a named running?"
    end

    Process.kill('INT', @pid)
    @pid = nil
  end

  def self.stop(named_root)
    pid = File.read("#{named_root}/tmp/named.pid").strip.to_i
    Process.kill('INT', pid)
  end

  def self.clean(named_root)
    FileUtils.cd named_root
    `rm -f tmp/*`
  end
end

if __FILE__ == $0
  # UPDATE AS NEEDED

  case ARGV[0]
  when "start"
    c = BindTestService.new named_dir

    c.reset
    c.start

  when "stop"
    BindTestService.stop named_dir

  when "clean"
    BindTestService.clean named_dir
  else

  end
end

