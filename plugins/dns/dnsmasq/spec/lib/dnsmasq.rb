#
# Create and control a DNSMasq service for testing
#

# for copying files and initializing the test service
require 'fileutils'

# The plugin extends classes in the StickShift controller module.
require 'rubygems'

# for process control
require 'open4'

class DnsMasqService

  @@dnsmasq = "/usr/sbin/dnsmasq"
  @@init_config = <<CONFIG
# DNSMasq config sample
no-hosts
no-resolv
keep-in-foreground
log-async

# BEGIN TXT RECORDS

CONFIG

  attr_reader :service_root, :port
  attr_reader :config_file, :hosts_file, :hosts_dir
  attr_reader :pid_file, :stdin, :stdout, :stderr
  attr_accessor :pid
  def initialize(
                 service_root= Dir.pwd + "/tmp", 
                 port = 2053,
                 a_records={}, 
                 txt_records={}
                 )
    @service_root = service_root
    @config_file = @service_root + "/dnsmasq.conf"
    @hosts_file = @service_root + "/dnsmasq.hosts"
    @hosts_dir = @service_root + "/dnsmasq.hosts.d"
    @pid_file = @service_root + "/dnsmasq.pid"

    @port = port

    @a_records = a_records
    @txt_records = txt_records
    reset @a_records, @txt_records

    if File.exists? @pid_file
      @pid = File.open(@pid_file).readline.to_i
    end
  end

  def start()

    tokens = [@@dnsmasq, "-C", @config_file, "-x", @pid_file, "-h", "-H", @hosts_file, "-H", @hosts_dir, "-p", @port]
    cmd = tokens.join(' ')

    # start the process, save the PID, connect the stdout, stderr
    @pid, @stdin, @stdout, @stderr = Open4::popen4 cmd

    # check for failed start?
    sleep(1)
    @stdin.close
    return @pid
  end

  def status()
    # check if the pid file exists
    File.exists? @pid_file or return false

    pid = File.open(@pid_file).readline.to_i

    # check if there's a matching process
    File.exists? "/proc/#{pid}" or return false

    return "pid #{pid} " + File.open("/proc/#{pid}/cmdline").readline.split("\u0000").join(" ")
  end

  def stop()
    # stop the process
    # send kill

    # Wait for exit
    pid = File.open(@pid_file).readline.to_i
    Process.kill "TERM", pid
    #if @pid
    #  Process.kill "TERM", @pid
    #  ignored, status = Process::waitpid2 @pid
    #  @pid = nil
    #else
    #  puts "Warning: No process to kill"
    #end

    # respond to status?
  end

  def clean() 
    # remove the artifacts
    if File.exists? @service_root and File.directory? @service_root
      FileUtils.rm_r(@service_root)
    end
  end

  def reset(a_records=nil, txt_records=nil)
    #puts "resetting #{a_records}, #{txt_records}"
    a_records ||= @a_records
    txt_records ||= @txt_records

    # clean and re-initialize
    clean()

    # create dir if it does not exist
    Dir.mkdir(@service_root) unless File.exists? @service_root and File.directory? @service_root

    # copy the config and hosts
    File.open(@config_file, 'w') {|f| f.write @@init_config}
    File.open(@hosts_file, 'w') {|f| f.write "127.255.255.255 verify.example.com\n"}
    # create the hosts.d directory
    Dir.mkdir @hosts_dir

    # add the TXT records to the config
    txt_records.each { |name, text| add_txt_record name, text }

    # add hosts records
    a_records.each { |name, ipaddr| add_a_record  name, ipaddr }

  end

  def add_a_record(hostname, ipaddr)
    # write a file named <hostname> with one line
    # containing "<ipaddr> <hostname>"
    # in @hosts_dir
    #puts "creating host file #{@hosts_dir}/#{hostname} containing #{ipaddr} #{hostname}"
    File.open("#{@hosts_dir}/#{hostname}", "w") {|f| f.write "#{ipaddr} #{hostname}\n"}
  end

  def add_txt_record(ipaddr, text)
    # write a line on the end of @config_file
    # containing "txt-record=<ipaddr>,<text>
    #puts "adding a text record"
    File.open(@config_file, "a") {|f| f.write "txt-record=#{ipaddr},#{text}\n" }
  end
end
