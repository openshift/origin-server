#Test each of the basic functions of the NsupdateDnsPlugin

require 'rubygems'

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
          :keyname => "example.com.key",
          :keyvalue => "examplekeyvalue",
          :keyalgorithm => "HMAC-MD5",
          :krb_principal => "kerberos_principal",
          :krb_keytab => "kerberos_keytable"
        }
      end

    end
   def config()
      Configuration.new
    end
  end

end

module OpenShift

  class DNSException < Exception ; end

  # Make private methods public for testing
  class NsupdatePlugin
    def test_add_cmd(fqdn, value)
      add_cmd(fqdn, value)
    end

    def test_del_cmd(fqdn)
      del_cmd(fqdn)
    end

  end

  describe NsupdatePlugin do

   before do
      #
      # Set the assumed service file configuration
      #
      @dns = {
        :service => "nsupdate",
        :server => "127.0.0.1",
        :port => "2053",
        :zone => "example.com",
        :domain_suffix => "example.com",
      }

      # Sample Configurations
      @config = {
        :tsig => {
          :server => "4.5.6.7",
          :port => 3053,
          :zone => "tsigapp.example.com",
          :domain_suffix => "tsigapp.example.com",
          :keyname => "tsigapp.example.com.key",
          :keyvalue => "tsigapp_key_value",
          :keyalgorithm => "HMAC-MD5"
        },

        :gss => {
          :server => "9.8.7.6",
          :port => 4053,
          :zone => "krbapp.example.com",
          :domain_suffix => "krbapp.example.com",
          :krb_principal => "krbuser",
          :krb_keytab => "/krb/keytab/filename"
        }
      }

      @plugin = NsupdatePlugin.new(@dns)

    end

    it "can be configured using an input hash" do
      tsig_dns = OpenShift::NsupdatePlugin.new @config[:tsig]
      tsig_dns.server.should be @config[:tsig][:server]
      tsig_dns.port.should be @config[:tsig][:port]
      tsig_dns.keyname.should be @config[:tsig][:keyname]
      tsig_dns.keyvalue.should be @config[:tsig][:keyvalue]
      tsig_dns.krb_principal.should be nil
      tsig_dns.krb_keytab.should be nil

      gss_dns = OpenShift::NsupdatePlugin.new @config[:gss]
      gss_dns.server.should be @config[:gss][:server]
      gss_dns.port.should be @config[:gss][:port]
      gss_dns.keyname.should be nil
      gss_dns.keyvalue.should be nil
      gss_dns.krb_principal.should be @config[:gss][:krb_principal]
      gss_dns.krb_keytab.should be @config[:gss][:krb_keytab]

    end

    it "can be configured using the Rails Application::Configuration object" do
      
      dns = OpenShift::NsupdatePlugin.new

      cfg = Rails.application.config.dns

      dns.server.should eq cfg[:server]
      dns.port.should eq cfg[:port]
      dns.keyname.should eq cfg[:keyname]
      dns.keyvalue.should eq cfg[:keyvalue]
      dns.krb_principal.should eq cfg[:krb_principal]
      dns.krb_keytab.should eq cfg[:krb_keytab]


    end


    it "generates add commands for TSIG credentials" do
      dns = OpenShift::NsupdatePlugin.new(@config[:tsig])

      fqdn = "testapp1-testns1." + dns.domain_suffix
      value = "node.example.com"

      cmd = dns.send(:add_cmd, fqdn, value)
      
      cmdlines = cmd.split "\n"
      cmdlines.length.should be === 7

      cmdlines[0].should be === "nsupdate <<EOF"
      cmdlines[1].should eq "key #{@config[:tsig][:keyalgorithm]}:#{@config[:tsig][:keyname]} #{@config[:tsig][:keyvalue]}"
      cmdlines[2].should eq "server #{@config[:tsig][:server]} #{@config[:tsig][:port]}"
      cmdlines[3].should eq "update add #{fqdn} 60 CNAME #{value}"
      cmdlines[4].should eq "send"
      cmdlines[5].should eq "quit"
      cmdlines[6].should eq "EOF"
    end

    it "generates delete commands for GSS credentials" do
      dns = OpenShift::NsupdatePlugin.new(@config[:tsig])

      fqdn = "testapp1-testns1." + dns.domain_suffix

      cmd = dns.send(:del_cmd, fqdn)
     
      cmdlines = cmd.split "\n"
      cmdlines.length.should be === 7

      cmdlines[0].should be === "nsupdate <<EOF"
      cmdlines[1].should eq "key #{@config[:tsig][:keyname]} #{@config[:tsig][:keyvalue]}"
      cmdlines[2].should eq "server #{@config[:tsig][:server]} #{@config[:tsig][:port]}"
      cmdlines[3].should eq "update delete #{fqdn}"
      cmdlines[4].should eq "send"
      cmdlines[5].should eq "quit"
      cmdlines[6].should eq "EOF"

    end

    it "generates add commands for GSS credentials" do

      cfg = @config[:gss]
      dns = OpenShift::NsupdatePlugin.new(cfg)

      fqdn = "testapp1-testns1." + dns.domain_suffix
      value = "node.example.com"

      cmd = dns.send(:add_cmd, fqdn, value)
      
      cmdlines = cmd.split "\n"
      cmdlines.length.should be === 8

      cmdlines[0].should eq "kinit -kt #{cfg[:krb_keytab]} #{cfg[:krb_principal]} && \\"
      cmdlines[1].should be === "nsupdate <<EOF"
      cmdlines[2].should eq ""
      cmdlines[3].should eq "server #{cfg[:server]} #{cfg[:port]}"
      cmdlines[4].should eq "update add #{fqdn} 60 CNAME #{value}"
      cmdlines[5].should eq "send"
      cmdlines[6].should eq "quit"
      cmdlines[7].should eq "EOF"

    end

    it "generates delete commands for GSS credentials" do

      cfg = @config[:gss]
      dns = OpenShift::NsupdatePlugin.new(cfg)

      fqdn = "testapp1-testns1." + dns.domain_suffix

      cmd = dns.send(:del_cmd, fqdn)
      
      cmdlines = cmd.split "\n"
      cmdlines.length.should be === 8

      cmdlines[0].should eq "kinit -kt #{cfg[:krb_keytab]} #{cfg[:krb_principal]} && \\"
      cmdlines[1].should eq "nsupdate <<EOF"
      cmdlines[2].should eq ""
      cmdlines[3].should eq "server #{cfg[:server]} #{cfg[:port]}"
      cmdlines[4].should eq "update delete #{fqdn}"
      cmdlines[5].should eq "send"
      cmdlines[6].should eq "quit"
      cmdlines[7].should eq "EOF"

    end

    
  end

end
