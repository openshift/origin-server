#
# Implement the StickShift::DnsService interface using DNSMasq
#
require 'rubygems'

# because namespace query is a real DNS query
require 'dnsruby'

# Process control
require 'open4'

module OpenShift

  # This class provides a means for an Openshift Origin broker service to publish
  # the presence and location of new applications. 
  # It implements the StickShift::DnsService interface.
  #
  # It uses a local dnsmasq[http://www.thekelleys.org.uk/dnsmasq/doc.html] service 
  # on the back end and manipulates the host and configuration files
  # to publish and unpublish application hostnames. 
  #
  # - http://www.thekelleys.org.uk/dnsmasq/doc.html - Dnsmasq home page
  #
  # Per the DnsService interface, hostnames are composed of three strings:
  #  <app_name>-<namespace>.<domain_suffix>
  # eg. app_name="app1", namespace="ns1", domain_suffix="example.com" yields
  #  app1-ns1.example.com
  #
  # 
  class DnsMasqPlugin < OpenShift::DnsService


    @oo_dns_provider = OpenShift::DnsMasqPlugin


    # the DNS server to query for response tests
    attr_reader :server

    # The port to use for DNS queries
    attr_reader :port

    # The zone to update when adding application hostnames
    attr_reader :zone

    # The DNS domain suffix to add to application hostnames
    attr_reader :domain_suffix

    # the location of the dnsmasq configuration file
    attr_reader :config_file

    # the location of the dnsmasq hosts directory
    attr_reader :hosts_dir

    # indicates that the dnsmasq is a system service
    attr_reader :system

    # The PID of a running Dnsmasq process when the service is active.  nil otherwise.
    attr_accessor :pid
    attr_reader :pid_file

    # DEPENDENCIES
    # Rails.application.config.ss[:domain_suffix]
    # Rails.application.config.dns[...]

    # --
    # Define stubs for the interface
    # ++

    # call-seq:
    #   DnsMasqPlugin.new(access_info = nil, system_service=true, pid=nil)
    # 
    # takes a single hash as input:
    #  access_info = {
    #   :server => String,
    #   :port => Integer,
    #   :zone => String,
    #   :domain_suffix => String,
    #   :config_file => String,
    #   :hosts_dir => String
    #  }
    def initialize(access_info = nil, system_service=true)

      if access_info != nil
        @domain_suffix = access_info[:domain_suffix]
      elsif defined? Rails
        access_info = Rails.application.config.dns
        @domain_suffix = Rails.application.config.openshift[:domain_suffix]
      else
        raise Exception.new("Dnsmasq DNS service is not initialized")
      end

      @server = access_info[:server]
      @port = access_info[:port]
      @zone = access_info[:zone]
      @config_file = access_info[:config_file]
      @hosts_dir = access_info[:hosts_dir]

      @system_service = system_service

      @pid_file = access_info[:pid_file]
      if @pid_file and File.exists? @pid_file
        @pid = File.open(@pid_file).readline.to_i
      else
        @pid = nil
      end

      # Internal control variables
      @pending_a_records = false
      @pending_txt_records = false

      # if this is a system service, determine which:
      if @system_service
        if File.exists? "/usr/bin/systemctl"
          @restart_cmd = "/usr/bin/systemctl restart dnsmasq"
        else
          @restart_cmd = "/usr/sbin/service dnsmasq restart"
        end
      end

    end

    # Determine if a namespace is available.
    # Return false if it has been reserved and true otherwise
    #--
    # this should probably be inherited: it's a straight TXT record query - MAL 20120831
    #++
    def namespace_available?(namespace)
      resolver = Dnsruby::Resolver.new({ :nameservers => [@server],
                                         :port => @port.to_s,
                                         :do_caching => false})

      begin
        response = resolver.query("#{namespace}.#{@domain_suffix}",
                                  Dnsruby::Types.TXT)
        return false
      rescue Dnsruby::NXDomain
        return true
      rescue Dnsruby::Refused
        # Dnsmasq returns this instead of NXDomain?
        return true
      end
    end

    # reserve the indicated namespace
    def register_namespace(namespace)
      # add a txt record to the config file

      if not self.namespace_available? namespace
        raise Exception.new "namespace #{namespace} is already reserved"
      end

      txt_option = "txt-record=#{namespace}.#{@domain_suffix},register #{namespace}\n"
      f = File.open(@config_file, "a")
      f.write(txt_option)
      f.close
      @pending_txt_records = true
    end

    # unreserve the indicated namespace
    def deregister_namespace(namespace)

      if self.namespace_available? namespace
        raise Exception.new "namespace #{namespace} is already free"
      end

      txt_re = Regexp.new "txt-record=#{namespace}.#{@domain_suffix}"
      fr = File.open(@config_file, "r")
      src = fr.readlines
      src.reject! { |l| l =~ txt_re }
      fw = fr.reopen(@config_file, "w")
      src.each {|l| fw.write l }
      fw.close
      @pending_txt_records = true

    end

    # publish the IP Name/Address of an application
    def register_application(app_name, namespace, public_hostname)

      # get the IP address of the public_hostname
      resolver = Dnsruby::Resolver.new({ :nameservers => [@server],
                                         :port => @port.to_s,
                                         :do_caching => false})

      # should catch lookup failure for node IP!
      responses = resolver.query(public_hostname)
      ip_address = responses.answer[0].address

      hostname = "#{app_name}-#{namespace}.#{@domain_suffix}"
      host_file_name = "#{@hosts_dir}/#{hostname}"
      host_entry = "#{ip_address} #{hostname}\n"
      f = File.open host_file_name, "w"
      f.write host_entry
      f.close

      @pending_a_records = true
    end

    # unpublish the IP Name/Address of an application
    def deregister_application(app_name, namespace)
      
      hostname = "#{app_name}-#{namespace}.#{@domain_suffix}"
      host_file_name = "#{@hosts_dir}/#{hostname}"

      if File.exists? host_file_name
        File.delete host_file_name
      else
        raise Exception "application #{hostname} is not registered"
      end

      @pending_a_records = true
    end

    # update the IP Name/Address of an application
    def modify_application(app_name, namespace, public_hostname)
      register_application app_name, namespace, public_hostname
    end
    
    # finalize accumulated updates (if needed)
    def publish

      if not @pid
        if File.exists? @pid_file
          @pid = File.open(@pid_file).readline.to_i
        else
          puts "no service running!"
          exit
        end
      end

      if @pending_txt_records 
        # if there are pending TXT record updates, kill and restart
        # if it's a system service, use the system tools
        
        # init system: use service dnsmasq restart

        # systemd: use systemctl restart dnsmasq

        # /proc/<pid>/cmdline reads as a null seperated sequence of character
        # strings in unicode.
        # MAL - really should trap file-not-found properly
        restart_cmd = File.open("/proc/#{@pid}/cmdline").readline.split("\u0000").join(" ")

        Process.kill "TERM", @pid
        ignored, status = Process::waitpid2 @pid
     
        # restart
        # start the process, save the PID, connect the stdout, stderr
        @pid, stdin, stdout, stderr = Open4::popen4 restart_cmd
        stdin.close
        stdout.close
        stderr.close

        sleep(1)

      elsif @pending_a_records
        # if there are pending A record updates, just send HUP
        Process.kill "HUP", @pid
        sleep 1
      end

      # reset pending records
      @pending_txt_records = nil
      @pending_a_records = nil
    end

    # end communications with the server through this instance
    def close
    end

  end

end
