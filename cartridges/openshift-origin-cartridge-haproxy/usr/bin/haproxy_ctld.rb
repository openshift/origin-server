#!/usr/bin/env oo-ruby
#
# Introduction
# ============
#
# haproxy_ctld.rb is the primary daemon that controls autoscaling on OpenShift.
# By customizing this script users can change the thresholds and algorithms
# used to control scale up and down behavior.
#
# Without changes, this script uses concurrent connections to determine when
# scale up and down events should occur.  This behavior was chosen by default
# because as more people are using the site, it's a common behavior to add
# more backends.  Also, as backends slow down, requests take longer and thus
# the number of requests outstanding at any point in time goes up which can
# be a good indication that more backends are needed.
#
# There are, however, several scenarios where using this method won't work or
# in some cases could be harmful to the performance of your application.  For
# example, if your data backend is the primary bottleneck, adding more
# application gears could actually harm performance, not increase it.  The
# documentation contained in this script are intended as a starting point for
# advanced users who wish to customize this script to be more application
# specific.
#
# Overview
# =======
#
# haproxy_ctld.rb runs inside the same gear as haproxy does.  Haproxy is our
# primary load balancing software.  Haproxy and haproxy_ctld.rb are both run
# as your user inside the gear and both are daemonized.  The default behavior
# is to have haproxy_ctld.rb watch haproxy via its unix socket "status" port
# to obtain basic statistics about haproxy.  When a scale up or down event
# is required, haproxy_ctld.rb contacts the broker via the standard REST API
# and issues a scale-up or scale-down event.  Authentication is handled by an
# auth token stored in the haproxy gear.  This token allows haproxy_ctld.rb to
# behave as the user, but with far reduced permissions.
#
# The goals of customizing this script to your own needs are as follows:
#
# 1) Determine clear metrics for when you would like your application to scale
#    up and scale down.
# 2) Find a mechanism for monitoring those metrics.
# 3) Customize this script accordingly
# 4) Test it out.
#
# One common request is something like: "I want to scale up with CPU reaches
# 90%."  To break that request down into an actionable item, first we have to
# identify which cpu is being discussed.  Presumably one of the application
# gears.  Keep in mind the haproxy gear doesn't have direct access to those
# gears but there is an SSH key on the haproxy that has ssh access.  This
# allows the haproxy to log in to remote gears and run commands in them to get
# whatever desired metrics might be required.
#
# The next step might be to determine what thresholds to use.  Should we scale
# up when just one gear is at 90%?  Should we scale up when 30% of the gears
# are at 90%?
#
# As your customizations mature, you'll need to add anti-flap and other
# protections.  In our 90% CPU example above, you wouldn't want to keep scaling
# up just because one gear is at 90%.  It could be a code bug that hit an
# infinite loop and without proper protections, your haproxy_ctld.rb script
# could keep issuing scale up events indefinitely.
#
# Advanced Topics and Ideas
# =========================
#
# In addition to scale up and down events, it should be possible to dynamically
# alter some haproxy settings.  In our 90% CPU example above, perhaps one out
# of 10 gears is at 90% while the others are only at 20.  Using the unix
# control port, users could dynamically change the weight of the busy gear so
# it is less favored until things even out.


require 'socket'
require 'logger'
require 'getoptlong'
require 'net/http'

#
# @check_interval = 5 (default)
#
# check_interval determines how often (in seconds) a the daemon should check
# for scale up/down events.
#
@check_interval=5

#
# FLAP_PROTECTION_TIME_SECONDS = 600 (default)
#
# Flap protection is an important setting for dealing with scale up and down
# events.  Constantly scaling up and down is not an attractive behavior and
# FLAP_PROTECTION_TIME_SECONDS is the amount of time (in seconds) required
# to pass after a scale up event has happened but before a scale down event
# occurs.  In other words, if a scale up event has happened, don't issue
# a scale down event until after 600 seconds has elapsed
#
FLAP_PROTECTION_TIME_SECONDS = 600

HAPROXY_CONF_DIR=File.join(ENV['OPENSHIFT_HAPROXY_DIR'], "conf")
HAPROXY_RUN_DIR=File.join(ENV['OPENSHIFT_HAPROXY_DIR'], "run")
HAPROXY_CONFIG=File.join(HAPROXY_CONF_DIR, "haproxy.cfg")
HAPROXY_STATUS_URLS_CONFIG=File.join(HAPROXY_CONF_DIR, "app_haproxy_status_urls.conf")
PID_FILE=File.join(HAPROXY_RUN_DIR, "haproxy_ctld.pid")

$shutdown = false

class HAProxyAttr
    attr_accessor :pxname,:svname,:qcur,:qmax,:scur,:smax,:slim,:stot,:bin,:bout,:dreq,:dresp,:ereq,:econ,:eresp,:wretr,:wredis,:status,:weight,:act,:bck,:chkfail,:chkremove,:lastchg,:removetime,:qlimit,:pid,:iid,:sid,:throttle,:lbtot,:tracked,:type,:rate,:rate_lim,:rate_max,:check_status,:check_code,:check_duration,:hrsp_1xx,:hrsp_2xx,:hrsp_3xx,:hrsp_4xx,:hrsp_5xx,:hrsp_other,:hanafail,:req_rate,:req_rate_max,:req_tot,:cli_abrt,:srv_abrt

    def initialize(line)
        (@pxname,@svname,@qcur,@qmax,@scur,@smax,@slim,@stot,@bin,@bout,@dreq,@dresp,@ereq,@econ,@eresp,@wretr,@wredis,@status,@weight,@act,@bck,@chkfail,@chkremove,@lastchg,@removetime,@qlimit,@pid,@iid,@sid,@throttle,@lbtot,@tracked,@type,@rate,@rate_lim,@rate_max,@check_status,@check_code,@check_duration,@hrsp_1xx,@hrsp_2xx,@hrsp_3xx,@hrsp_4xx,@hrsp_5xx,@hrsp_other,@hanafail,@req_rate,@req_rate_max,@req_tot,@cli_abrt,@srv_abrt) = line.split(',')
    end
end

class Haproxy
    #
    # MAX_SESSIONS_PER_GEAR = 16.0 (default)
    #
    # Sessions per gear is the primary control for determining how much traffic
    # an individual gear can handle.  It is highly likely users will want to
    # tune this up and down.  If your backend is doing small and fast jobs like
    # might be the case for a caching service (varnish), you may want to
    # increase this number.  If the backend process is doing heavy processing
    # and likely takes a while, you may want to lower this number.
    #
    # Note: This doesn't control how many requests go to a backend gear, this
    # simply tells haproxy_ctld.rb how many connections per gear we are
    # targeting so it can scale up and down to match that ratio.
    #
    MAX_SESSIONS_PER_GEAR = ENV['OPENSHIFT_MAX_SESSIONS_PER_GEAR'] ? ENV['OPENSHIFT_MAX_SESSIONS_PER_GEAR'].to_f : 16.0
    MOVING_AVERAGE_SAMPLE_SIZE = 10

    attr_accessor :gear_count, :sessions, :sessions_per_gear, :session_capacity_pct, :gear_namespace, :last_scale_up_time, :last_scale_error_time, :previous_stats, :status_urls_config_mtime, :stats, :previous_remote_sessions_counts

    class ShouldRetry < StandardError
      attr_reader :message
      def initialize(message)
        @message=message
      end
      def to_s
        "An error occurred; try again later: #{@message}"
      end
    end


    def populate_status_urls(check_mtime=false)
      @status_urls = []
      if File.exist?(HAPROXY_STATUS_URLS_CONFIG)
        mt = File.mtime(HAPROXY_STATUS_URLS_CONFIG)
        previous_status_urls_config_mtime = status_urls_config_mtime
        status_urls_config_mtime = mt
        if check_mtime && previous_status_urls_config_mtime
          return unless mt > previous_status_urls_config_mtime
        end
        begin
          File.open(HAPROXY_STATUS_URLS_CONFIG, "r").each_line do |surl|
            @status_urls << surl.strip
          end
        rescue => ex
          @log.error(ex.backtrace)
        end
      end
    end


    def initialize(stats_sock="#{HAPROXY_RUN_DIR}/stats", log_debug=nil)
        @previous_stats = []
        @previous_remote_sessions_counts = {}
        @stats_sock=stats_sock
        @gear_namespace = ENV['OPENSHIFT_GEAR_DNS'].split('.')[0].split('-')[1]

        # don't buffer log output or it may never make it to logshifter
        STDOUT.sync=true
        STDERR.sync=true
        @log = Logger.new(STDOUT)
        if log_debug
          @log.level = Logger::DEBUG
        else
          @log.level = Logger::INFO
        end

        @last_scale_up_time=Time.now
        # remove_count_threshold defines how long @session_gear_pct must be
        # below @gear_remove_pct.
        @remove_count_threshold = 20
        @remove_count = 0
        self.populate_status_urls
        self.refresh(false)
        @log.info("Starting haproxy_ctld")
        self.print_gear_stats
    end

    def get_remote_sessions_count(status_url)
      @log.debug("Getting stats from #{status_url}")
      status_uri = status_url + ";csv"
      begin
        output = Net::HTTP.get(URI(status_uri))

        status = {}
        output.split("\n")[1..-1].each do |line|
          pxname = line.split(',')[0]
          svname = line.split(',')[1]
          status[pxname] = {} unless status[pxname]
          status[pxname][svname] = HAProxyAttr.new(line)
        end

        num_sessions = status['express']['BACKEND'].scur.to_i
        previous_remote_sessions_counts[status_url] = [] unless previous_remote_sessions_counts[status_url]
        prsc = previous_remote_sessions_counts[status_url]
        prsc << num_sessions
        prsc.delete_at(0) if prsc.length > MOVING_AVERAGE_SAMPLE_SIZE
        moving_avg_num_sessions = (prsc.reduce(:+).to_f / prsc.length).to_i
        moving_avg_num_sessions
      rescue => ex
        @log.error("Failed to get stats from #{status_url}")
        @log.debug(ex.backtrace)
        -1
      end
    end

    def refresh(log_error_on_should_retry=true, stats_sock="#{HAPROXY_RUN_DIR}/stats")
        populate_status_urls(true)
        @previous_stats << @stats if @stats
        @previous_stats.delete_at(0) if @previous_stats.length > MOVING_AVERAGE_SAMPLE_SIZE
        @stats = {}

        begin
          @socket = UNIXSocket.open(@stats_sock)
          @socket.puts("show stat\n")
          while(line = @socket.gets) do
            pxname=line.split(',')[0]
            svname=line.split(',')[1]
            @stats[pxname] = {} unless @stats[pxname]
            @stats[pxname][svname] = HAProxyAttr.new(line)
          end
          @socket.close
        rescue Errno::ENOENT => e
          @log.error("A retryable error occurred: #{e}") if log_error_on_should_retry
          raise ShouldRetry, e.to_s
        rescue Errno::ECONNREFUSED
          @log.error("Could not connect to the application.  Check if the application is stopped.") if log_error_on_should_retry
          raise ShouldRetry, "Could not connect to the application.  Check if the application is stopped."
        end

        @gear_count = self.stats['express'].count - 2
        @gear_up_pct = 90.0
        if @gear_count > 1
          # Pick a percentage for removing gears which is a moderate amount below the threshold where the gear would scale back up.
          @gear_remove_pct = (@gear_up_pct * ([1-(1.0 / @gear_count), 0.85].max)) - (@gear_up_pct / @gear_count)
        else
          @gear_remove_pct = 1.0
        end
        @sessions = num_sessions('express', 'BACKEND')
        if @gear_count == 0
          @log.error("Failed to get information from haproxy") if log_error_on_should_retry
          raise ShouldRetry, "Failed to get information from haproxy"
        end

        @log.debug("Local sessions #{@sessions}")
        num_remote_proxies = 0
        @status_urls.each do |surl|
          num_sessions = get_remote_sessions_count(surl)
          @log.debug("Remote sessions #{surl} #{num_sessions}")
          if num_sessions >= 0
            @sessions += num_sessions
            num_remote_proxies += 1
          end
        end

        @log.debug("Got stats from #{num_remote_proxies} remote proxies.")
        @sessions_per_gear = @sessions.to_f / @gear_count
        @session_capacity_pct = (@sessions_per_gear / MAX_SESSIONS_PER_GEAR ) * 100
    end

    def num_sessions(pvname, svname)
      num = 0
      count = 1
      if stats && stats[pvname] && stats[pvname][svname]
        num += stats[pvname][svname].scur.to_i
        previous_stats.each do |s|
          if s[pvname] && s[pvname][svname]
            num += s[pvname][svname].scur.to_i
            count += 1
          end
        end
      end
      (num.to_f / count).to_i
    end

    def last_scale_up_time_seconds
        seconds = Time.now - @last_scale_up_time
        seconds.to_i
    end

    def last_scale_error_time_seconds
        if last_scale_error_time
          seconds = Time.now - last_scale_error_time
          seconds.to_i
        else
          0
        end
    end

    def seconds_left_til_remove
        seconds = FLAP_PROTECTION_TIME_SECONDS - self.last_scale_up_time_seconds
        seconds.to_i
    end

    def add_gear(debug=false, exit_on_error=false)
        @last_scale_up_time = Time.now
        @log.info("add-gear - capacity: #{self.session_capacity_pct}% gear_count: #{self.gear_count} sessions: #{self.sessions} up_thresh: #{@gear_up_pct}%")
        gear_scale('add-gear', debug, exit_on_error)
        self.print_gear_stats
    end

    def remove_gear(debug=false, exit_on_error=false)
        @log.info("remove-gear - capacity: #{self.session_capacity_pct}% gear_count: #{self.gear_count} sessions: #{self.sessions} remove_thresh: #{@gear_remove_pct}%")
        gear_scale('remove-gear', debug, exit_on_error)
        self.print_gear_stats
    end

    def gear_scale(action, debug, exit_on_error)
      begin
        res=`#{ENV['OPENSHIFT_HAPROXY_DIR']}/usr/bin/#{action} -n #{self.gear_namespace} -a #{ENV['OPENSHIFT_APP_NAME']} -u #{ENV['OPENSHIFT_GEAR_UUID']} 2>&1`
        exit_code = $?.exitstatus
        @log.info("#{action} - exit_code: #{exit_code}  output: #{res}")
        if exit_code != 0
          if exit_on_error
            $stderr.puts res
            exit 1
          end
          @last_scale_error_time = Time.now
        else
          @last_scale_error_time = nil
        end
        self.populate_status_urls
      rescue => e
        @log.info("#{action} failure: #{e.message}")
        @log.info e.backtrace.join('\n') if debug
        @last_scale_error_time = Time.now
      end
    end

    def print_gear_stats
        self.refresh
        if self.seconds_left_til_remove > 0
            seconds_left = self.seconds_left_til_remove
        else
            seconds_left = 0
        end
        @log.debug("GEAR_INFO - capacity: #{session_capacity_pct}% gear_count: #{gear_count} sessions: #{sessions} up/remove_thresh: #{@gear_up_pct}%/#{@gear_remove_pct}% sec_left_til_remove: #{seconds_left} gear_remove_thresh: #{@remove_count}/#{@remove_count_threshold}")
    end


    #
    # Does a capacity check and issues scale up and down events.
    #
    # This is the primary area users will want to customize.  It's heavily 
    # targeted towards haproxy capacity today so feel free to gut and customize
    # as required.
    #
    # This gets called every 5 seconds (by default, determined by
    # check_interval defined above).
    #
    # Variables currently being used:
    #
    #   * @session_capcity_pct (determines how full current capacity is using
    #                          defined in "refresh" above).  100% full means
    #                          that all gears have all MAX_SESSIONS_PER_GEAR
    #                          or higher usage).  Though this number could be
    #                          higher than 100% in times of high load.  This
    #                          number will change up and down as more or fewer
    #                          people visit your site.
    #   * @gear_up_pct - Determines the level where @session_capacity_pct will
    #                    trigger a gear up event.
    #   * @gear_remove_pct - Determines the level where @session_capacity_pct
    #                        will issue a gear down event.
    #   * @gear_count - The number of gears currently defined in haproxy
    #   * @last_scale_up_time_seconds - How long it's been since we last scaled
    #                                   up.  Used for flap prevention
    #   * @remove_count - Number of consecutive remove_gear requests
    #   * @remove_count_threshold - The number of checks in a row where
    #                               @session_capacity_pct must be below
    #                               @gear_remove_pct before self.remove_gear
    #                               will be called.
    #
    def check_capacity(debug=nil)
        lsets = last_scale_error_time_seconds
        if lsets == 0 || lsets > FLAP_PROTECTION_TIME_SECONDS
          min, max = get_scaling_limits

          #
          # Check to see if @session_capacity_pct is greater than or equal to
          # @gear_up_pct.  If it is, issue a gear up event and log it.  Then
          # return back to the checker program.
          #
          # This would be one of the first areas that could be completely
          # removed or customized.  For example, users that wanted to scale up
          # when memory on a remote gear was high could do something like the
          # pseudo code below:
          #
          # for gear_dns in gear_list
          #     mem_usage = `ssh -i ~/.openshift_ssh/id_rsa/$UUID@$gear_dns 'oo-cgroup-read memory.memsw.usage_in_bytes'`
          #     self.add_gear if mem_usage >= 10000000
          # end
          #
          # Or in another example, we could track CPU deltas using cgroups.
          # This would require storing current and previous cpu to generate a
          # delta.  Again, more pseudo code.
          #
          # for gear_dns in gear_list
          #     current_cpu_usage = `ssh -i ~/.openshift_ssh/id_rsa/$UUID@$gear_dns 'oo-cgroup-read cpuacct.usage'`
          #     cpu_delta = current_cpu_usage - previous_cpu_usage
          #     self.add_gear if cpu_delta >= 152504356
          # end
          #
          # Another option is to create a tester script that you want to finish
          # in a certain time.  If it's slower than expected, scale up.  Be
          # careful not to create a heisenberg script (IE: a script that might
          # change the performance of the gear simply by running it).  This can
          # happen when doing a lot of compute.
          #
          # for gear_dns in gear_list
          #     time_threshold = 2 # seconds
          #     test_script_time = `ssh -i ~/.openshift_ssh/id_rsa/$UUID@$gear_dns 'my_test_script.sh'`
          #     self.add_gear if time_test_script > time_threshold
          # end
          if @session_capacity_pct >= @gear_up_pct
              @remove_count = 0
              if @gear_count < max or max < 0
                self.add_gear
              else
                  @log.error("Cannot add gear, max gears already met")
                  @log.error("max: #{max} gearcount: #{@gear_count}")
              end
              self.print_gear_stats if debug
          elsif @session_capacity_pct < @gear_remove_pct and @gear_count > 1
              #
              # Removing gears is a bit more complicated almost entirely
              # because flap detection is currently built to err on the side of
              # performance.  That is, as soon as we've hit a threshold to
              # scale up, do so.  However scaling down must meet not just a
              # threshold but also several flapping rules.  This may or may
              # not be what you want.
              #
              # Current scale down rules:
              #
              # If @session_capacity_pct is less than @gear_remove_pct
              #   and
              # @gear_count is greater than 1 (to prevent scaling down to 
              #   zero gears)
              #   and
              # the last gear up happened longer than
              #   FLAP_PROTECTION_TIME_SECONDS ago
              #   and
              # @remove_count is larger than @remove_count_threshold
              #   then
              # self.remove_gear
              #
              # Remember that @remove_count_threshold is the number of checks
              # in a row that must be met before a gear down event happens.  It
              # could be that the very moment you checked haproxy, there
              # weren't many people connected, but overall things might be
              # extremely busy.
              #
              #
              # This will be the second area you are likely to customize.  The
              # examples made above for scale up events will very likely require
              # scale down changes in this section.  The most complicated part
              # of the current code is all in the flap detection.  It is highly
              # recommended not to start with flap detection built in.  Keep
              # it simple and then adjust your code as you need to.  Here
              # are some sample gear down events without flap detection.
              #
              #
              # This example shows the below code with flap detection removed:
              #
              # if @session_capacity_pct < @gear_remove_pct and @gear_count > 1
              #   self.remove_gear
              # end
              #
              # Using one of the above examples with memory, this example
              # issues a scale down when memory usage drops below a threshold.
              #
              # for gear_dns in gear_list
              #     mem_usage = `ssh -i ~/.openshift_ssh/id_rsa/$UUID@$gear_dns 'oo-cgroup-read memory.memsw.usage_in_bytes'`
              #     self.remove_gear if mem_usage < 10000000
              # end
              #
              @remove_count += 1 if @remove_count < @remove_count_threshold

              if self.last_scale_up_time_seconds.to_i > FLAP_PROTECTION_TIME_SECONDS
                  if @remove_count >= @remove_count_threshold
                      self.remove_gear if @gear_count > min
                      @remove_count = 0
                  else
                      self.print_gear_stats if debug
                  end
              else
                  self.print_gear_stats if debug
              end
              # End of scale down section
          else
              @remove_count = 0
              self.print_gear_stats if debug
          end
        else
          @log.debug("Skipping check_capacity for #{FLAP_PROTECTION_TIME_SECONDS - lsets}s due to a previous failed scale operation") if debug
        end
    end

    def get_scaling_limits
      data_dir = ENV['OPENSHIFT_DATA_DIR']
      scale_file = "#{data_dir}/scale_limits.txt"
      min = 1
      max = -1
      if File.exists? scale_file
        scale_data = File.read(scale_file)
        scale_hash = {}
        scale_data.split("\n").each { |s|
          line = s.split("=")
          scale_hash[line[0]] = line[1]
        }
        begin
          min = scale_hash["scale_min"].to_i
          max = scale_hash["scale_max"].to_i
        rescue Exception => e
          @log.error("Unable to get gear's min/max scaling limits because of #{e.message}")
        end
      end
      return min, max
    end

end

def p_usage(rc=0)
    puts <<USAGE

Usage: #{$0}
Control scaling features for this application.  Has two operating modes, auto
and manual.  Manual scaling options will run requested action and exit, auto
scaling options will stay running in the foreground.

  -h|--help         Display this help menu

Manual scaling options:
  -u|--up           Trigger a gear_up event and add an additional gear
  -d|--down         Trigger a gear_remove event and remove a gear
  --debug           Puts logger into debug mode

Auto scaling options:
  -a|--auto         Enable auto-scale
  --debug           Puts logger into debug mode
USAGE
    exit! rc
end

begin
    opts = GetoptLong.new(
        ["--up", "-u", GetoptLong::NO_ARGUMENT],
        ["--down", "-d", GetoptLong::NO_ARGUMENT],
        ["--auto", "-a", GetoptLong::NO_ARGUMENT],
        ["--debug", GetoptLong::NO_ARGUMENT],
        ["--help",  "-h", GetoptLong::NO_ARGUMENT]
    )
    opt = {}
    opts.each do |o, a|
        if (o == "--help") or (o == "-h")
            p_usage
        end
        opt[o[2..-1]] = a.to_s
    end
rescue Exception => e
  p_usage(255)
end

data_dir = ENV['OPENSHIFT_DATA_DIR']
scale_file = "#{data_dir}/scale_limits.txt"
File.delete(scale_file) if File.exists?(scale_file)

if opt['up'] || opt['down']
  begin
    ha = Haproxy.new("#{HAPROXY_RUN_DIR}/stats", opt['debug'])
    if opt['up']
      ha.add_gear(opt['debug'], true)
      exit 0
    elsif opt['down']
      ha.remove_gear(opt['debug'], true)
      exit 0
    end
  rescue Haproxy::ShouldRetry => e
    puts e.message
    exit 1
  end
else
  trap("TERM") do
    $shutdown = true
  end

  File.open(PID_FILE, "w") do |f|
    f.write(Process.pid)
  end

  ha = nil
  while not $shutdown
    begin
      if ha
        ha.refresh
      else
        ha = Haproxy.new("#{HAPROXY_RUN_DIR}/stats", opt['debug'])
      end
      ha.check_capacity(opt['debug'])
    rescue Haproxy::ShouldRetry => e
      # Already logged when the exception was generated
    end
    sleep @check_interval
  end

  begin
    # Due to the sleep above, it's possible the TERM signal was received
    # up to @check_interval seconds earlier, and another haproxy_ctld.rb 
    # has been launched and overwritten the pid_file, so do not remove the
    # pid_file unless it contains our pid.
    pid=File.read(PID_FILE)
    File.delete(PID_FILE) unless pid.to_i != Process.pid
  rescue
    # ignore
  end
end
