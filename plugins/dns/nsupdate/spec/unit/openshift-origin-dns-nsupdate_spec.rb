#Test each of the basic functions of the NsupdateDnsPlugin

require 'rubygems'
require 'dnsruby'

# the plugin extends classes in the OpenShift::Controller module
# load the superclass for all DnsService classes: Openshift::DnsService
require 'openshift/dns_service'

# Now load the plugin code itself (not the wrapper!)
require 'openshift/nsupdate_plugin'

#
# Define the Rails config structure for testing
#

module Rails
  def self.application()
    Application.new
  end

  class Application

    class Configuration
      attr_accessor :openshift, :dns

      def initialize()
        @openshift = { :domain_suffix => "example.com" }
        @dns = {
          :server => "ns1.example.com",
          :port => 2053,
          :zone => "example.com",
          :config_file => "/etc/dnsmasq.conf",
          :hosts_dir => "/etc/dnsmasq.d",
          :system => false,
          :pid_file => "/var/run/dnsmasq.pid"
        }
      end

    end
   def config()
      Configuration.new
    end
  end

end

module OpenShift

  describe NsupdatePlugin do

   before do
      # create a DnsMasq service to work with
      #@service = DnsMasqService.new

      #puts "new service = @service"

      #
      # Set the assumed service file configuration
      #
      @dns = {
        :service => "dnsmasq",
        :server => "127.0.0.1",
        :port => "2053",
        :zone => "example.com",
        :domain_suffix => "example.com",
        #:config_file => @service.config_file,
        #:hosts_dir => @service.hosts_dir,
        #:pid_file => @service.pid_file
      }

      @plugin = NsupdatePlugin.new(@dns)

      @resolver = 
        Dnsruby::Resolver.new({
                                :nameservers => [@dns[:server]], 
                                :port => @dns[:port].to_s,
                                :do_caching => false
                              })
    end

    after do
      # Stop and clean the DnsMasq service workspaces
      #@service.stop if @service.pid
      #@service.clean
    end

    it "can be configured using an input hash" do
      uplift = OpenShift::NsupdatePlugin.new @dns
      #uplift.config_file.should be @dns[:config_file]
      #uplift.hosts_dir.should be @dns[:hosts_dir]
      #uplift.pid.should be @dns[:pid]
    end

    it "can be configured using the Rails Application::Configuration object" do
      

      uplift = OpenShift::NsupdatePlugin.new

    end


  end

end
