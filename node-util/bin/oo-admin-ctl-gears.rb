#!/usr/bin/env oo-ruby
#--
# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++


# TODO:
#   Timeouts
#   USR1

require 'rubygems'
require 'openshift-origin-node/utils/node_logger'
require 'openshift-origin-node/model/application_container'

module OpenShift
  class AdminGearsControl
    @@RED = "\033[31m"
    @@GREEN = "\033[32m"
    @@NORMAL = "\033[0m"

    @@DEFAULT_SLOTS = 5

    def initialize(container_uuid=nil)
      @uuid = container_uuid
      
      @nslots = @@DEFAULT_SLOTS

      if container_uuid.nil?
        NodeLogger.logger.debug("Setting for all gears with #{@nslots} parallel")
      else
        NodeLogger.logger.debug("Setting for gear #{container_uuid}")
      end

      # Gears is protected between threads by the global interpretor lock.
      @readers = Hash.new

      @generator = nil
    end

    def start
      p_runner do |gear|
        output_pass_fail("Starting") do
          gear.start_gear
        end
      end
    end

    def stop
      p_runner do |gear|
        output_pass_fail("Stopping") do
          gear.stop_gear
        end
      end
    end

    def restart
      p_runner do |gear|
        output_pass_fail("Restarting") do
          gear.restart_gear
        end
      end
    end

    def status
      $stdout.puts("Checking OpenShift Services: ")
      $stdout.puts("")
      p_runner(false) do |gear|
        $stdout.puts("Checking application #{gear.container_name} status:")
        $stdout.puts("-----------------------------------------------")
        begin
          gear.cartridge_model.each_cartridge do |cart|
            gear.status(cart.name)
          end
        rescue => e
          $stderr.puts("Gear #{gear.container_name} Exception: #{e}")
          $stderr.puts("Gear #{gear.container_name} Backtrace: #{e.backtrace}")
        end
        $stdout.puts("")
      end
    end

    def p_runner(skip_stopped=true)
      parallelize do |p|
        gears(skip_stopped).each do |gear|
          p.call do
            if block_given?
              yield(gear)
            end
          end
        end
      end
    end

    def gear_uuids(skip_stopped=true)
      Enumerator.new do |yielder|
        gears(skip_stopped).each do |gear|
          yielder.yield(gear.uuid)
        end
      end
    end


    private

    # Private: Enumerate all non-stopped gears.
    def gears(skip_stopped=true)
      Enumerator.new do |yielder|
        if @uuid
          gear = ApplicationContainer.from_uuid(uuid)
          if skip_stopped & gear.stop_lock?
            raise ArgumentError, "Gear is locked: #{uuid}"
          end
          gear_set = [gear]
        else
          gear_set = ApplicationContainer.all_containers
        end
        gear_set.each do |gear|
          begin
            if not (skip_stopped & gear.stop_lock?)
              yielder.yield(gear)
            end
          rescue => e
            NodeLogger.logger.error("Gear evaluation failed for: #{gear.uuid}")
            NodeLogger.logger.error("Exception: #{e}")
            NodeLogger.logger.error("#{e.backtrace}")
          end
        end
      end
    end

    # Private: yield a function which can be used to parallelize gear
    # method calls.
    def parallelize
      @generator = Thread.new do
        if block_given?
          yield(gen_background_task)
        end
      end

      rv = collect_output
      @generator.join
      rv
    end

    # Private: Respond with pass/fail
    def output_pass_fail(message)
      lambda do
        rc = 0
        begin
          $stdout.write("#{message} #{gear.uuid}... ")
          if block_given?
            yield
          end
          NodeLogger.logger.notice("#{message} #{gear.uuid}... [ OK ]")
          $stdout.write("[ #{@GREEN}OK#{@NORM} ]\n")
        rescue => e
          NodeLogger.logger.debug("Gear: #{gear.uuid} Exception #{e.inspect}")
          NodeLogger.logger.debug("Gear: #{gear.uuid} Backtrace #{e.backtrace}")
          NodeLogger.logger.error("#{message} #{gear.uuid}: [ FAIL ]")
          NodeLogger.logger.error("#{message} #{gear.uuid}: Error: #{e}")
          $stdout.write("[ #{@RED}FAILED#{@NORM} ]\n")
          e.to_s.lines.each do |el|
            $stdout.write("      #{el}\n")
          end
          rc=254
        end
        rc
      end
    end

    # Private: Generate a backgrounded task
    def gen_background_task
      lambda do |&block|
        while @readers.length > @nslots
          Thread.stop
        end

        reader, writer = IO::pipe

        pid = Process.fork do
          reader.close
          rc = 0
          begin
            writer.sync
            $stdin.reopen("/dev/null", 'r')
            $stdout.reopen(writer)
            $stdout.sync
            $stderr.reopen(writer)
            $stderr.sync

            ObjectSpace.each_object(IO) do |i|
              next if i.closed?
              next if [$stdin, $stdout, $stderr, writer].map { |f| f.fileno }.include?(i.fileno)
              i.close
            end
            NodeLogger.logger_rebuild

            if not block.nil?
              rc = block.call
            end

          ensure
            exit(rc.to_i)
          end
        end

        writer.close

        # Add to the listener list
        @readers[reader.fileno] = {:pid => pid, :reader => reader, :buf => "" }

      end
    end

    # Private: Collect output and status for children and send to stdout.
    #
    # Note: This will buffer stdout indefinitely to avoid slowing down
    # the children.
    #
    # Note: to allow for new processes and a changing descriptor set,
    # the set of file descriptors are re-checked every 0.1 seconds.
    #
    def collect_output
      outbuf = ""
      retcode = 0
      readers = []

      while @generator.alive? or not readers.empty? or not outbuf.empty?

        fdlookup = {}
        fdpids = {}
        readers = []

        @readers.each_pair do |k, v|
          readers << v[:reader]
        end

        writers=[]
        if not outbuf.empty?
          writers=[$stdout]
        end

        fds = select(readers, writers, nil, 0.1)
        next if fds.nil?
        # Process waiting pipe reads
        fds[0].uniq.each do |fd|
          begin
            @readers[fd.fileno][:buf] << fd.read_nonblock(32768)
          rescue IO::WaitReadable
          rescue EOFError
            # If too soon, next select will return this fd again.
            cpid, status = Process.waitpid2(@readers[fd.fileno][:pid], Process::WNOHANG)
            if not cpid.nil?
              retcode |= status.exitstatus
              fileno = fd.fileno
              outbuf << @readers[fileno][:buf]
              @readers[fileno][:reader].close
              @readers.delete(fileno)
              NodeLogger.logger.debug("Finished: #{cpid} Status: #{status.exitstatus}")
              @generator.wakeup if @generator.alive?
            end
          end
        end

        # Process output to stdout
        fds[1].each do |fd|
          begin
            outbytes = fd.write_nonblock(outbuf)
            outbuf = outbuf[outbytes..-1]
          rescue IO::WaitWritable
          end
        end

      end

      retcode
    end


  end
end


$lockfile = "/var/lock/subsys/openshift-gears"
$gearsfile = "/var/log/openshift-gears-async-start.log"

def lock_if_good
  if block_given?
    r = yield
    if r.to_i == 0
      File.open($lockfile, 'w') {}
    end
  end
  r
end

def unlock_if_good
  if block_given?
    r = yield
    if r.to_i == 0
      begin
        File.unlink($lockfile)
      rescue Errno::ENOENT
      end
    end
  end
  r
end


exitval = 0
begin
  case ARGV[0]
  when 'startall'
    cpid = fork do
      Dir.chdir('/')
      $stdin.reopen('/dev/null', 'r')
      $stdout.reopen($gearsfile, 'w')
      $stderr.reopen($stdout)            
      ObjectSpace.each_object(IO) do |i|
        next if i.closed?
        next if [$stdin, $stdout, $stderr].map { |f| f.fileno }.include?(i.fileno)
        i.close
      end
      Process.setsid
      NodeLogger.logger_rebuild
      exitval = lock_if_good do
        OpenShift::AdminGearsControl.new.start
      end
      exit(exitval)
    end
    NodeLogger.logger.notice("Background start initiated - process id = $cpid")
    NodeLogger.logger.notice("Check $gearsfile for more details.")
    $stdout.puts "Background start initiated - process id = $cpid"
    $stdout.puts "Check $gearsfile for more details."
    $stdout.puts
    $stdout.puts "Note: In the future, if you wish to start the OpenShift services in the"
    $stdout.puts "      foreground (waited), use:  service openshift-gears waited-start"
    $stdout.flush
    exit!(0)

  when 'stopall'
    exitval = unlock_if_good {
      OpenShift::AdminGearsControl.new.stop
    }

  when 'restartall'
    exitval = lock_if_good {
      OpenShift::AdminGearsControl.new.restart
    }

  when 'condrestartall'
    if File.exists?($lockfile)
      exitval = OpenShift::AdminGearsControl.new.restart
    end

  when 'waited-startall'
    exitval = lock_if_good {
      OpenShift::AdminGearsControl.new.start
    }

  when 'status'
    exitval = OpenShift::AdminGearsControl.new.status    

  when 'startgear'
    raise "Requires a gear uuid." if ARGV[1].nil?
    exitval = OpenShift::AdminGearsControl.new(ARGV[1]).start

  when 'stopgear'
    raise "Requires a gear uuid." if ARGV[1].nil?
    exitval = OpenShift::AdminGearsControl.new(ARGV[1]).stop
    
  when 'restartgear'
    raise "Requires a gear uuid." if ARGV[1].nil?
    exitval = OpenShift::AdminGearsControl.new(ARGV[1]).restart

  when 'statusgear'
    raise "Requires a gear uuid." if ARGV[1].nil?
    exitval = OpenShift::AdminGearsControl.new(ARGV[1]).status    

  when 'list'
    OpenShift::AdminGearsControl.new.gear_uuids(false).each do |uuid|
      $stdout.puts uuid
    end

  else
    raise "Usage: #{$0} {startall|stopall|status|restartall|condrestartall|startgear|stopgear|restartgear|list}"
  end

rescue => e
  $stderr.puts(e.to_s)
  $stderr.puts(e.backtrace)
  exit 1
end

exit(exitval.to_i)
