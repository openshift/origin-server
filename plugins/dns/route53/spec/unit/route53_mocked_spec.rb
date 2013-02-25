#Test each of the basic functions of the NsupdateDnsPlugin

require 'rubygems'

# the plugin extends classes in the OpenShift::Controller module
# load the superclass for all DnsService classes: Openshift::DnsService
require 'openshift/dns_service'

require 'openshift/route53_plugin'

$hosted_zone = "apps.example.com"
$hosted_zone_id = "MYHOSTEDZONEID"
$aws_access_key_id = "MYAWSACCESSKEYIDLALA"
$aws_access_key = "notaR33lAws4ccessk3ylalalalasisboombahla"
$test_nodename = "node1.example.com"
$test_appname = "app1"
$test_namespace = "ns1"

# Mock up the rails application configuration object
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
          :zone => $hosted_zone,
          :aws_hosted_zone_id => $hosted_zone_id,
          :aws_access_key_id => $aws_access_key_id,
          :aws_access_key => $aws_access_key,
          :ttl => 10
        }
      end

    end

    def config()
     Configuration.new
    end
  end
end




module OpenShift

  describe Route53Plugin do

    before(:each) do

      @sample_list = {
        :resource_record_sets=>[
          {:resource_records=>[{:value=>"node1.example.com."}], 
            :name=>"app1-ns1.apps.example.com.", :type=>"CNAME", :ttl=>30}
        ],
        :is_truncated=>false,
        :max_items=>1
      }

      @sample_request = {
          :comment => "",
          :changes => {
            :action => "",
            :resource_record_set => {
              :name => "app1-ns1.apps.example.com",
              :type => "CNAME",
              :ttl => 30,
              :resource_records => [{:value => "node1.example.com"}],
            }
          }
        }

       
      @change_result = {
        :change_info => {
          :changes => [],
          :status => "PENDING",
          :id => "/change/ABCDEFGABCDEFG"
        }
      }

      AWS::Route53::Client.any_instance.stub(:list_resource_record_sets).and_return(@sample_list)
      AWS::Route53::Client.any_instance.stub(:change_resource_record_sets).and_return(@change_result)
    end

    it "can be initialized with arguments" do
      
      dns_service = 
        Route53Plugin.new({
                                  :domain_suffix => $hosted_zone,
                                  :aws_hosted_zone_id => $hosted_zone_id,
                                  :aws_access_key_id => $aws_access_key_id,
                                  :aws_access_key => $aws_access_key,
                                  :ttl => 20
                                })
      dns_service.aws_hosted_zone_id.should be == $hosted_zone_id
      dns_service.aws_access_key_id.should be == $aws_access_key_id
      dns_service.aws_access_key.should be == $aws_access_key
      dns_service.ttl.should be == 20
    end

    it "can be initialized from the Rails Application configuration" do
      dns_service = Route53Plugin.new()
      dns_service.aws_hosted_zone_id.should be == $hosted_zone_id
      dns_service.aws_access_key_id.should be == $aws_access_key_id
      dns_service.aws_access_key.should be == $aws_access_key
      dns_service.ttl.should be == 10
    end

    it "can add application records to Route53" do
      #set_test_record("DELETE")
      # should call change_test_record_set
      # with structure = 

      # should recieve response: 

      dns_service = Route53Plugin.new()
      reply = dns_service.register_application($test_appname, 
                                               $test_namespace,
                                               $test_nodename)

      message = reply[:change_info]
      message[:status].should be == "PENDING"
      message[:id].should match(/\/change\/[A-Z]+/)
                                       
    end


    it "can delete application records from Route53" do
      #set_test_record("CREATE")
      # should call list_test_record_set
      # with structure = 

      # should recieve response:

      # should call change_test_record_set
      # with structure = 

      # should recieve response: 

      dns_service = Route53Plugin.new()
      reply = dns_service.deregister_application($test_appname, 
                                                 $test_namespace)

      message = reply[:change_info]
      message[:status].should be == "PENDING"
      message[:id].should match(/\/change\/[A-Z]+/)

    end

    it "can modify existing application records on Route53" do
      #set_test_record("CREATE")
      # should call list_test_record_set
      # with structure = 

      dns_service = Route53Plugin.new()
      reply = dns_service.modify_application(
        $test_appname, 
        $test_namespace,
        $test_nodename
        )

      # should recieve response:
      message = reply[:change_info]
      message[:status].should be == "PENDING"
      message[:id].should match(/\/change\/[A-Z]+/)

    end

    it "can retrieve application records from Route53" do
      # should call list_test_record_set
      # with structure = 

      # should recieve response:

      pending "not defined"
    end

  end

end
