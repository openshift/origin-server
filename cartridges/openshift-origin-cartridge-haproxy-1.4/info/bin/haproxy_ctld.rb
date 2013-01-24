#!/usr/bin/env oo-ruby

require 'socket'
require 'logger'
require 'getoptlong'

@check_interval=3

CONFIG_VALIDATION_CHECK_INTERVAL=300
HAPROXY_CONF_DIR=File.join(ENV['OPENSHIFT_HOMEDIR'], "haproxy-1.4", "conf")
HAPROXY_RUN_DIR=File.join(ENV['OPENSHIFT_HOMEDIR'], "haproxy-1.4", "run")
GEAR_REGISTRY_DB=File.join(HAPROXY_CONF_DIR, "gear-registry.db")
HAPROXY_CONFIG=File.join(HAPROXY_CONF_DIR, "haproxy.cfg")

class Haproxy_attr
    attr_accessor :pxname,:svname,:qcur,:qmax,:scur,:smax,:slim,:stot,:bin,:bout,:dreq,:dresp,:ereq,:econ,:eresp,:wretr,:wredis,:status,:weight,:act,:bck,:chkfail,:chkremove,:lastchg,:removetime,:qlimit,:pid,:iid,:sid,:throttle,:lbtot,:tracked,:type,:rate,:rate_lim,:rate_max,:check_status,:check_code,:check_duration,:hrsp_1xx,:hrsp_2xx,:hrsp_3xx,:hrsp_4xx,:hrsp_5xx,:hrsp_other,:hanafail,:req_rate,:req_rate_max,:req_tot,:cli_abrt,:srv_abrt

    def initialize(line)
        (@pxname,@svname,@qcur,@qmax,@scur,@smax,@slim,@stot,@bin,@bout,@dreq,@dresp,@ereq,@econ,@eresp,@wretr,@wredis,@status,@weight,@act,@bck,@chkfail,@chkremove,@lastchg,@removetime,@qlimit,@pid,@iid,@sid,@throttle,@lbtot,@tracked,@type,@rate,@rate_lim,@rate_max,@check_status,@check_code,@check_duration,@hrsp_1xx,@hrsp_2xx,@hrsp_3xx,@hrsp_4xx,@hrsp_5xx,@hrsp_other,@hanafail,@req_rate,@req_rate_max,@req_tot,@cli_abrt,@srv_abrt) = line.split(',')
    end
end

class HaproxyUtils
    @@log = Logger.new("#{ENV['OPENSHIFT_HAPROXY_LOG_DIR']}/validate_config.log")
    def self.parse_gear_registry_info(ginfo)
        gbits = ginfo.split(";")
        uuid = gbits[0].split("@")[0]
        ipaddr = gbits[0].split("@")[1].split(":")[0]
        return [gbits[1], uuid, ipaddr]
    end

    def self.get_gear_ipaddress(gdns, ipaddr)
        gip = ipaddr
        begin
            gip = IPSocket.getaddress(gdns)
        rescue Exception => ex
            @@log.error("Unable to get gear's IP address for #{gdns}: #{ex.message} - using default #{ipaddr}")
        end
        return gip
    end

    def self.repair_configuration(gdns, uuid, oldipaddr, newipaddr, debug=nil)
        return false  if oldipaddr == newipaddr  # Don't do unneccessary work.

        @@log.debug("GEAR_INFO - repair: Repairing gear registry - #{gdns} now resolves to #{newipaddr} (was #{oldipaddr}) ...") if debug
        cfgdata = File.readlines(GEAR_REGISTRY_DB)
        cfgdata.map! {|line| line.gsub(/#{uuid}\@[0-9.]+:/, "#{uuid}@#{newipaddr}:") }
        File.open(GEAR_REGISTRY_DB, "w") {|file| file.puts cfgdata }
        @@log.info("GEAR_INFO - repair: Repaired gear registry - #{gdns} now resolves to #{newipaddr} (was #{oldipaddr})")

        gear_name = gdns.split(".")[0]
        @@log.debug("GEAR_INFO - validate: Repairing haproxy config - #{gdns} now resolves to #{newipaddr} (was #{oldipaddr}) ...") if debug
        hacfgdata = File.readlines(HAPROXY_CONFIG)
        hacfgdata.map! {|line| line.gsub(/\s*server\s*gear-#{gear_name}\s*[0-9.]+:/, "    server gear-#{gear_name} #{newipaddr}:") }
        File.open(HAPROXY_CONFIG, "w") {|file| file.puts hacfgdata }
        @@log.info("GEAR_INFO - repair: Repaired haproxy config - #{gdns} now resolves to #{newipaddr} (was #{oldipaddr})")
        return true
    end

    def self.validate_configuration(debug=nil)
        repaired = false
        cfg=File.open(GEAR_REGISTRY_DB).read
        cfg.gsub!(/\r\n?/, "\n")
        cfg.each_line do |line|
            gentry = line.delete("\n")
            gdns, uuid, ipaddr = HaproxyUtils.parse_gear_registry_info(gentry)
            gearip = HaproxyUtils.get_gear_ipaddress(gdns, ipaddr)

            @@log.debug("GEAR_INFO - validate: Verifying gear #{gdns} resolves to #{ipaddr} for uuid=#{uuid} ... ") if debug
            if ipaddr != gearip
                @@log.info("GEAR_INFO - validate: Repairing configuration to use IP address #{gearip} for gear #{gdns} ...")
                repaired ||= HaproxyUtils.repair_configuration(gdns, uuid, ipaddr, gearip)
            end
        end

        if repaired
            @@log.info("GEAR_INFO - validate: Configuration was modified, reloading haproxy")
            ENV["CARTRIDGE_TYPE"] = "haproxy-1.4"
            exec "app_ctl.sh reload"
        end
    end
end

class Haproxy
    #ha=Haproxy.new("#{HAPROXY_RUN_DIR}/stats")
    #gear_namespace=ENV['OPENSHIFT_GEAR_DNS'].split('.')[0].split('-')[1]
    #gear_count = ha.stats['express'].count - 3.0 # Remove backend, frontend and 'filler'
    #sessions = ha.stats['express']['BACKEND'].scur.to_f
    #sessions_per_gear = sessions / gear_count
    #session_capacity_pct = (sessions_per_gear / @max_sessions_per_gear ) * 100

    class ShouldRetry < StandardError
      attr_reader :message
      def initialize(message)
        @message=message
      end
      def to_s
        "An error occurred; try again later: #{@message}"
      end
    end

    def initialize(stats_sock="#{HAPROXY_RUN_DIR}/stats")
        @stats_sock=stats_sock
        @last_scale_up_time=Time.now
        @flap_protection_time_seconds = 120 # number of seconds to ignore gear remove events since last up event
        @remove_count_threshold = 20
        @remove_count = 0
        self.refresh
        @log.info("Starting haproxy_ctld")
        self.print_gear_stats
    end

    def refresh(stats_sock="#{HAPROXY_RUN_DIR}/stats")
        @max_sessions_per_gear=10.0
        @gear_remove_pct = 49.9
        @gear_up_pct = 90.0
        @gear_namespace = ENV['OPENSHIFT_GEAR_DNS'].split('.')[0].split('-')[1]
        @log = Logger.new("#{ENV['OPENSHIFT_HAPROXY_LOG_DIR']}/scale_events.log")

        @status={}

        begin
          @socket = UNIXSocket.open(@stats_sock)
          @socket.puts("show stat\n") 
          while(line = @socket.gets) do
            pxname=line.split(',')[0]
            svname=line.split(',')[1]
            @status[pxname] = {} unless @status[pxname]
            @status[pxname][svname] = Haproxy_attr.new(line)
          end
          @socket.close
        rescue Errno::ENOENT => e
          @log.error("A retryable error occurred: #{e}")
          raise ShouldRetry, e.to_s
        end

        @gear_count = self.stats['express'].count - 3
        @sessions = self.stats['express']['BACKEND'].scur.to_i
        if @gear_count == 0
          raise ShouldRetry, "Failed to get information from haproxy"
          @log.error("Failed to get information from haproxy")
        end

        @sessions_per_gear = @sessions / @gear_count
        @session_capacity_pct = @session_capacity_pct = (@sessions_per_gear / @max_sessions_per_gear ) * 100

    end

    def gear_namespace()
        @gear_namespace
    end

    def last_scale_up_time()
        @last_scale_up_time
    end

    def last_scale_up_time_seconds()
        seconds = Time.now - @last_scale_up_time
        seconds.to_i
    end

    def seconds_left_til_remove()
        seconds = @flap_protection_time_seconds - self.last_scale_up_time_seconds
        seconds.to_i
    end

    def gear_count()
        @gear_count
    end

    def sessions()
        @sessions
    end

    def sessions_per_gear()
        @sessions_per_gear
    end

    def session_capacity_pct()
        @session_capacity_pct
    end

    def add_gear(verbose=false)
        @last_scale_up_time = Time.now
        @log.info("GEAR_UP - capacity: #{self.session_capacity_pct}% gear_count: #{self.gear_count} sessions: #{self.sessions} up_thresh: #{@gear_up_pct}%")
        res=`add-gear -n #{self.gear_namespace}  -a #{ENV['OPENSHIFT_APP_NAME']} -u #{ENV['OPENSHIFT_APP_UUID']}`
        @log.debug("GEAR_UP - add-gear: exit: #{$?}  stdout: #{res}")
        $stderr.puts(res) if verbose and res != ""
        self.print_gear_stats
    end

    def remove_gear(verbose=false)
        @log.info("GEAR_DOWN - capacity: #{self.session_capacity_pct}% gear_count: #{self.gear_count} sessions: #{self.sessions} remove_thresh: #{@gear_remove_pct}%")
        res=`remove-gear -n #{self.gear_namespace} -a #{ENV['OPENSHIFT_APP_NAME']} -u #{ENV['OPENSHIFT_APP_UUID']}`
        @log.debug("GEAR_DOWN - remove-gear: exit: #{$?}  stdout: #{res}")
        $stderr.puts(res) if verbose and res != ""
        self.print_gear_stats
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

    def check_capacity(debug=nil)
        # check_capacity tracks the following information for determing whether
        # or not to increase or decrease a gear
        #
        # @session_capacity_pct (%full considering total number of gears and
        #       current sessions
        # @gear_up_pct - When capacity is larger then gear_up_pct, add a gear
        # @gear_remove_pct - When capacity is less then gear_remove_pct, remove a
        #       gear
        # @gear_count - The number of gears (don't remove a gear when there's
        #       only one left.
        # @last_scale_up_time_seconds - how long it's been since we last scaled
        #       up
        # @flap_protection_time_seconds - The number of seconds to wait until
        #       triggering a gear_remove event
        # @remove_count - Number of consecutive remove_gear requests
        # @remove_count_threshold - when remove_count meets remove_count_threshold
        #       actually issue a remove_gear

        min, max = get_scaling_limits

        # If active capacity is greater then gear_up pct. Add a gear
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
            # If active capacity is less then gear remove percentage
            # *AND* the last gear up happened longer then
            # ago @flap_protection_time_seconds
            # *AND* remove_count is larger then the remove_count_threshold
            # Gear remove.

            @remove_count += 1 if @remove_count < @remove_count_threshold

            if self.last_scale_up_time_seconds.to_i > @flap_protection_time_seconds
                if @remove_count >= @remove_count_threshold
                    self.remove_gear if @gear_count > min
                    @remove_count = 0
                else
                    self.print_gear_stats if debug
                end
            else
                self.print_gear_stats if debug
            end
        else
            @remove_count = 0
            self.print_gear_stats if debug
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
          @@log.error("Unable to get gear's min/max scaling limits because of #{e.message}")
        end
      end
      return min, max
    end

    def stats()
        @status
    end

    def scur()
        @scur
    end

end

def p_usage
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

Notes:
1. To start/stop auto scaling in daemon mode run:
    haproxy_watcher (start|stop|restart|run|)
USAGE
    exit 255
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
  p_usage
end


begin
  data_dir = ENV['OPENSHIFT_DATA_DIR']
  scale_file = "#{data_dir}/scale_limits.txt"
  File.delete(scale_file) if File.exists?(scale_file) 
  ha=Haproxy.new("#{HAPROXY_RUN_DIR}/stats")
  if opt['up']
    ha.add_gear(true)
    exit 0
  elsif opt['down']
    ha.remove_gear(true)
    exit 0
  end
rescue Haproxy::ShouldRetry => e
  puts e
  exit 1
end

last_cfg_check_time=0
while true
    begin
      ha.refresh()
      ha.check_capacity(opt['debug'])
    rescue Haproxy::ShouldRetry => e
      # Already logged when the exception was generated
    end
    sleep @check_interval
    if (Time.now - last_cfg_check_time).to_i > CONFIG_VALIDATION_CHECK_INTERVAL
        last_cfg_check_time = Time.now
        HaproxyUtils.validate_configuration()
    end
end
