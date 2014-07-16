require 'parseconfig'
require 'openshift/dns_service'
require 'openshift/fog_plugin'

# Mock up the rails application configuration object
module Rails
  def self.application()
    Application.new
  end

  class Application

    class Configuration
      attr_accessor :dns
      
      def initialize()
        conf_file = File.expand_path('../../../conf/openshift-origin-dns-fog.conf.example', __FILE__);
        conf = ParseConfig.new(conf_file)

        @dns = {
          :provider => conf["FOG_PROVIDER"],
          :zone => conf["FOG_ZONE"],
          :rackspace_username => conf["FOG_RACKSPACE_USERNAME"],
          :rackspace_api_key => conf["FOG_RACKSPACE_API_KEY"],
          :rackspace_region => conf["FOG_RACKSPACE_REGION"],
        }
      end
    end

    def config()
     Configuration.new
    end
  end
end

module OpenShift

  describe FogPlugin do

    def mock_fog

    end

    before(:all) do
      $test_appname = "testapp"
      $test_namespace = "ns"
      $test_hostname = "test.com"
      $fqdn = "#{$test_appname}-#{$test_namespace}.#{Rails.application.config.dns[:zone]}"
    end

    it "can be initialized with arguments" do
      
      fog_options = {
        provider: 'fogProvider',
        zone: 'fogZone',
        rackspace_username: 'username',
        rackspace_api_key: 'apikey',
        rackspace_region: 'region'
      };

      dns_service = FogPlugin.new(fog_options)
      expect(dns_service.zone).to eql('fogZone')
      expect(dns_service.config).to include(
        :provider => 'fogProvider',
        :rackspace_username => 'username',
        :rackspace_api_key => 'apikey',
        :rackspace_region => 'region' )
    end

    it "can be initialized from the Rails Application configuration" do
      dns_service = FogPlugin.new()

      expected_config = Rails.application.config.dns
      expect(dns_service.zone).to eql(expected_config[:zone])
      expect(dns_service.config).to include(
        :provider => expected_config[:provider],
        :rackspace_username => expected_config[:rackspace_username],
        :rackspace_api_key => expected_config[:rackspace_api_key],
        :rackspace_region => expected_config[:rackspace_region] )
    end

    it "can add application records to fog" do
      record = double( :destroy => {}, :save => {} )
      records = double( :records => double( :create => {}, :find => record  ) ) 
      zone = double("zone", :find => records )
      fog = double("fog", :zones => zone)
      allow(Fog::DNS).to receive(:new) { fog }

      dns_service = FogPlugin.new()
      reply = dns_service.register_application($test_appname, 
                                               $test_namespace,
                                               $test_hostname)

      expectedCreatePayload = {
        :name => $fqdn,
        :type => 'CNAME',
        :value => $test_hostname
      }
      expect(zone.find.records).to have_received(:create).with(expectedCreatePayload)
                                       
    end

    it "can delete application records from fog" do
      record = double( :destroy => {}, :save => {} )
      records = double( :records => double( :create => {}, :find => record  ) ) 
      zone = double("zone", :find => records )
      fog = double("fog", :zones => zone)
      allow(Fog::DNS).to receive(:new) { fog }

      dns_service = FogPlugin.new()
      reply = dns_service.deregister_application($test_appname, 
                                                 $test_namespace)

      expect(record).to have_received(:destroy)
    end

    it "can modify application records from fog" do
      record = double( :destroy => {}, :save => {}, :name= => '', :value= => '')
      records = double( :records => double( :create => {}, :find => record  ) ) 
      zone = double("zone", :find => records )
      fog = double("fog", :zones => zone)
      allow(Fog::DNS).to receive(:new) { fog }

      dns_service = FogPlugin.new()
      new_name = $test_hostname + 'new'
      reply = dns_service.modify_application($test_appname, 
                                             $test_namespace,
                                             new_name)

      expect(record).to have_received(:name=).with($fqdn)
      expect(record).to have_received(:value=).with(new_name)
      expect(record).to have_received(:save)
    end
  end
end
