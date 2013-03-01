#Test each of the basic functions of the NsupdateDnsPlugin

require 'rubygems'
require 'dnsruby'
require 'parseconfig'


# the plugin extends classes in the OpenShift::Controller module
# load the superclass for all DnsService classes: Openshift::DnsService
require 'openshift/dns_service'

require 'openshift/route53_plugin'

#
# Check for AWS credentials
#
cfgfile = ENV['HOME'] + "/.awscred"

if ENV['AWSAccessKeyId'] and ENV['AWSSecretKey'] then
  $aws_access_key_id = ENV['AWSAccessKeyId']
  $aws_secret_key = ENV['AWSSecretKey']
elsif File.exists? cfgfile then
  cfg = ParseConfig.new(cfgfile)
  $aws_access_key_id = cfg['AWSAccessKeyId']
  $aws_access_key = cfg['AWSSecretKey']
else
  raise Exception.new("Missing required AWS Credentials")
end

$hosted_zone = ENV['AWS_ROUTE53_HOSTED_ZONE']
$hosted_zone_id = ENV['AWS_ROUTE53_HOSTED_ZONE_ID']

$test_namespace = ENV['AWS_ROUTE53_TEST_NAMESPACE'] || "pluginns1"
$test_appname = ENV['AWS_ROUTE53_TEST_APPNAME'] || "pluginapp1"
$test_nodename = ENV['AWS_ROUTE53_TEST_NODENAME'] || "pluginnode1.#{$hosted_zone}"

if ! $hosted_zone or ! $hosted_zone_id then
  puts "Missing envvars: AWS_ROUTE53_HOSTED_ZONE and/or AWS_ROUTE53_HOSTED_ZONE_ID"
  exit
  raise Exception.new("Missing required AWS Route 53 Configuration: hosted_zone or hosted_zone_id")
end

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

def get_record(fqdn)
  r53 = AWS::Route53.new(:access_key_id => $aws_access_key_id,
                         :secret_access_key => $aws_access_key).client

  # Request a single record "starting with" the desired record.
  reply = r53.list_resource_record_sets(
                                        :hosted_zone_id => $hosted_zone_id,
                                        :start_record_name => fqdn,
                                        :max_items => 1
                                        )

  # If the returned record name matches exactly, return it.
  # record fqdn are returned with the trailing anchor (.)

  return nil if not reply
  
  res = reply[:resource_record_sets][0]
  return nil if not res

  return res if (res[:name] == fqdn + ".")

  nil
end

# Add a record with the correct signature for testing
def set_test_record(action)

  # Here's the record name we want
  fqdn = "#{$test_appname}-#{$test_namespace}.#{$hosted_zone}"

  reply = get_record(fqdn)
  
  # If it's not there and that's what we want, we're done
  return if (action == "DELETE" and reply == nil)

  record = reply[:resource_records][0]
  public_hostname = record[:value]

  # If we already have the right record, we're done
  return if (action == "CREATE" and public_hostname == $test_nodename)

  
  return if ((not get_record(fqdn) == nil) ^ (action == "DELETE"))

  change_record = {
    :action => action,
    :resource_record_set => {
      :name => fqdn,
      :type => "CNAME",
      :ttl => 10,
      :resource_records => [{:value => "\"#{$test_nodename}\""}],
    }
  }

  add_record = {
    :comment => "set a test record",
    :changes => [change_record]
  }
  
  r53 = AWS::Route53.new(:access_key_id => $aws_access_key_id,
                         :secret_access_key => $aws_access_key).client

  res = r53.change_resource_record_sets({:hosted_zone_id => $hosted_zone_id,
                                          :change_batch => add_record})

  change_id = res[:change_info][:id]

  accepted = false

  while accepted == false do
    sleep 5
    poll = r53.get_change({:id => res[:change_info][:id]})

    if poll[:change_info][:status] === "INSYNC" then
      accepted = true
    end

  end  
end

module OpenShift

  describe Route53Plugin do

    it "can be initialized with arguments" do
      
      set_test_record("DELETE")

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
      set_test_record("DELETE")

      dns_service = Route53Plugin.new()
      reply = dns_service.register_application($test_appname, 
                                               $test_namespace,
                                               $test_nodename)

      message = reply[:change_info]
      message[:status].should be == "PENDING"
      message[:id].should match(/\/change\/[A-Z]+/)
                                       
    end


    it "can delete application records from Route53" do
      set_test_record("CREATE")

      dns_service = Route53Plugin.new()
      reply = dns_service.deregister_application($test_appname, 
                                                 $test_namespace)

      message = reply[:change_info]
      message[:status].should be == "PENDING"
      message[:id].should match(/\/change\/[A-Z]+/)

    end

    it "can modify existing application records on Route53" do

    end

    it "can retrieve application records from Route53" do

    end
  end

end
