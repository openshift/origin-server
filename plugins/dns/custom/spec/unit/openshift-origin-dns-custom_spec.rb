#Test each of the basic functions of the NsupdateDnsPlugin

require 'rubygems'

# the plugin extends classes in the OpenShift::Controller module
# load the superclass for all DnsService classes: Openshift::DnsService
require 'openshift/dns_service'

# Now load the plugin code itself (not the wrapper!)
require 'openshift/custom_dns_plugin'

#
# Define the Rails config structure for testing
#

$hosted_zone = "apps.example.com"
$dns_custom_script = "/usr/local/bin/ose-dns-custom"

module Rails
  def self.application()
    Application.new
  end

  class Application

    class Configuration
      attr_accessor :openshift, :dns

      def initialize()
        @openshift = { :domain_suffix => $hosted_zone }
        @dns = {
          :dns_custom_script => "/usr/local/bin/ose-dns-custom",
        }
      end

    end
   def config()
      Configuration.new
    end
  end

end


module OpenShift

  describe CustomDNSPlugin do

   before do

      # Set the assumed service file configuration
      @dns = {
        :dns_custom_script => "/usr/local/bin/ose-dns-custom",
      }

      @plugin = CustomDNSPlugin.new(@dns)

    end

    it "can be configured using the Rails Application::Configuration object" do
      
      dns = OpenShift::CustomDNSPlugin.new
      cfg = Rails.application.config.dns

    end


    
  end

end
