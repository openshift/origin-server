# Test each of the basic functions of the DnsMasqDnsService plugin class

# The plugin extends classes in the StickShift controller module.
require 'rubygems'

# for testing DNS resolution
require 'dnsruby'

# load the superclass for the all DNSService classes - StickShift::DnsService
require 'openshift/dns_service'

# Now load the plugin code itself (not the wrapper!)
require 'openshift-origin-dns-dnsmasq/lib/openshift/dnsmasq-plugin'

require 'dnsmasq'

#
# Define Rails config structure for testing
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



#
# The Openshift (Dynamic DNS) interface has few methods and very little in the way of
# return value checks.
#
# Given that we can decide what to return and then test for it.
#

describe DnsMasqService do

end

module OpenShift

  describe DnsMasqPlugin do

    before do
      # create a DnsMasq service to work with
      @service = DnsMasqService.new

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
        :config_file => @service.config_file,
        :hosts_dir => @service.hosts_dir,
        :pid_file => @service.pid_file
      }

      @plugin = DnsMasqPlugin.new(@dns)

      @resolver = 
        Dnsruby::Resolver.new({
                                :nameservers => [@dns[:server]], 
                                :port => @dns[:port].to_s,
                                :do_caching => false
                              })
    end

    after do
      # Stop and clean the DnsMasq service workspaces
      @service.stop if @service.pid
      @service.clean
    end

    #
    # 
    #
  
    it "can be configured using an input hash" do
      uplift = OpenShift::DnsMasqPlugin.new @dns
      uplift.config_file.should be @dns[:config_file]
      uplift.hosts_dir.should be @dns[:hosts_dir]
      uplift.pid.should be @dns[:pid]
    end

    it "can be configured using the Rails Application::Configuration object" do
      

      uplift = OpenShift::DnsMasqPlugin.new

    end

    #
    # Test namespace methods
    #

    it "can test if a namespace is reserved" do
      @service.reset({}, {"reserved.example.com" => "a reserved namespace"})
      pid = @service.start
      # see if the PID is still
      @plugin.namespace_available?("reserved").should be_false
    end

    it "can test if a namespace is availabe" do
      @service.reset({}, {"reserved.example.com" => "a reserved namespace"})
      pid = @service.start
      # see if the PID is still
      @plugin.namespace_available?("available").should be_true
    end

    it "can reserve a namespace" do
      @service.reset({}, {"reserved" => "namespace reserved is reserved"})
      @service.start

      @plugin.register_namespace("new").should be_true

      @plugin.publish

      @plugin.namespace_available?("new").should be_false

    end

    it "rejects registering a reserved namespace" do
      @service.reset({}, {"reserved.example.com" => "a reserved namespace"})
      @service.start
      # raise an exception? OpenShift::DnsServiceError?
      expect {
        @plugin.register_namespace("reserved")
      }.to raise_error(Exception)
    end

    it "can release a namespace" do
      @service.reset({}, {"remove.example.com" => "a namespace to remove"})
      @service.start

      @plugin.deregister_namespace("remove").should be_true
      @plugin.publish
      @plugin.namespace_available?("remove").should be_true
    end

    it "rejects deregistering an unregistered namespace" do
      @service.reset({}, {})
      @service.start

      # raise an exception? OpenShift::DnsServiceError
      expect {
        @plugin.deregister_namespace("free").should be_false
      }.to raise_error(Exception)
    end

    #
    # Application Publication methods
    #

    it "can publish an application hostname" do
      @service.reset({"node.example.com" => "1.2.3.4"}, 
                     {"ns1.example.com" => "an existing namespace"})
      @service.start
      # check that app1.ns1.example.com does not resolve

      reg_response = @plugin.register_application("app1", "ns1", "node.example.com")
      # what should it return?

      pub_response = @plugin.publish

      # it takes time for the service to restart
      sleep 1

      # and what should that return

      # test that app1-ns1.example.com resolves
      response = @resolver.query("app1-ns1.example.com", Dnsruby::Types.A)
      # must be successful return
      response.rcode.should be == "NOERROR"
      response.answer.size.should be == 1
      response.answer[0].name.to_s().should be == "app1-ns1.example.com"
      response.answer[0].address.to_s().should be == "1.2.3.4"
    end

    it "can unpublish an application hostname" do
      @service.reset({"remove-ns1.example.com" => "3.2.1.1"}, 
                     {"ns1.example.com" => "an existing namespace"})
      pid = @service.start
      @plugin.pid = pid
      
      @plugin.deregister_application("remove", "ns1")
      # What should it return?

      @plugin.publish

      # test that remove-ns1.example.com no longer resolves
      # with real DNS you have to wait for TTL to expire

      expect {
        response = @resolver.query("remove-ns1.example.com",Dnsruby::Types.A)
      }.to raise_error(Dnsruby::Refused)

    end
      
    it "can update a published application hostname" do
      @service.reset(
                     {
                       "modify-ns1.example.com" => "4.5.6.7",
                       "node1.example.com" => "4.5.6.7",
                       "node2.example.com" => "4.5.6.8"
                     }, 
                     {"ns1.example.com" => "an existing namespace"}
                     )
      @service.start
      # test that modify-ns1.example.com resolves with IP 4.5.6.7

      @plugin.modify_application("modify", "ns1", "4.5.6.8")

      @plugin.publish

      # wait for the server to restart
      sleep 2
      # test that modify-ns1.example.com resolves with 4.5.6.8
      response = @resolver.query("modify-ns1.example.com", Dnsruby::Types.A)

      response.answer[0].address.to_s.should be == "4.5.6.8"

    end

    it "can restart the dynect daemon" do
      @service.reset
      pid = @service.start

      # Tell the plugin what the PID of the service is
      # MAL - should it just try reading the pid file?
      @plugin.pid = pid

      # force restart by simulating a TXT record update
      @plugin.instance_variable_set(:@pending_txt_records, true)

      @plugin.publish

      # reset the test service information
      @service.pid = @plugin.pid

      # 
      @plugin.pid.should_not eql(pid)
      
    end
  end
end
