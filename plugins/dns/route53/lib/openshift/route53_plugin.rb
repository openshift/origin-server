#
# Make OpenShift updates to Amazon Web Services Route53 DNS service
#
# http://docs.aws.amazon.com/AWSRubySDK/latest/frames.html
# http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/Route53/Client.html
#
require 'rubygems'
require 'aws-sdk'

module OpenShift

  # Implement the OpenShift::DnsService interface using AWS Route53
  # 
  class Route53Plugin < OpenShift::DnsService
    @oo_dns_provider = OpenShift::Route53Plugin

    # DEPENDENCIES
    # Rails.application.config.openshift[:domain_suffix]
    # Rails.application.config.dns[...]

    attr_reader :aws_hosted_zone_id
    attr_reader :aws_access_key_id, :aws_access_key, :ttl

    def initialize(access_info = nil)
      if access_info != nil
        @domain_suffix = access_info[:domain_suffix]
      elsif defined? Rails
        # extract from Rails.application.config[dns,ss]
        access_info = Rails.application.config.dns
        @domain_suffix = Rails.application.config.openshift[:domain_suffix]
      else
        raise Exception.new("AWS Route 53 DNS service is not initialized")
      end      
      @aws_hosted_zone_id = access_info[:aws_hosted_zone_id]
      @aws_access_key_id = access_info[:aws_access_key_id]
      @aws_access_key = access_info[:aws_access_key]
      @ttl = access_info[:ttl].to_i || 30 # default 30 sec
    end

    #
    # Publish the location of an application
    #
    # INPUTS:
    #   app_name:        String: the name of the application
    #   namespace:       String: avoid customer app name collisions
    #   public_hostname: String: Fully qualified domain name of the host
    #                            on which the app resides
    # RETURNS:
    #   The result of the change request, including the request ID for
    #   polling the request status
    #
    def register_application(app_name, namespace, public_hostname)

      # create an A record for the application in the domain
      fqdn = "#{app_name}-#{namespace}.#{@domain_suffix}"

      # create an update record

      update = {
        :comment => "Add an application record for #{fqdn}",
        :changes => [change_record("CREATE", fqdn, @ttl, public_hostname)]
      }
      
      res = r53.change_resource_record_sets({
                                              :hosted_zone_id => @aws_hosted_zone_id,
                                              :change_batch => update
                                            })
    end

    #
    # Un-publish the location of an application
    #
    # INPUTS:
    #   app_name:        String: the name of the application
    #   namespace:       String: avoid customer app name collisions
    #
    # RETURNS:
    #   The result of the change request, including the request ID for
    #   polling the request status
    #
    def deregister_application(app_name, namespace)
      # delete the CNAME record for the application in the domain
      fqdn = "#{app_name}-#{namespace}.#{@domain_suffix}"

      # Get the record you mean to delete.
      # We need the TTL and value to delete it.
      record = get_record(fqdn)

      # If record is nil, then we're done.  Raise an exception for trying?
      return if record == nil
      ttl = record[:ttl]
      public_hostname = record[:resource_records][0][:value]

      delete = {
        :comment => "Delete an application record for #{fqdn}",
        :changes => [change_record("DELETE", fqdn, @ttl, public_hostname)]
      }
      
      res = r53.change_resource_record_sets({
                                              :hosted_zone_id => @aws_hosted_zone_id,
                                              :change_batch => delete
                                            })
    end
  
    #
    # Change the published location of an application
    #
    # INPUTS:
    #   app_name:        String: the name of the application
    #   namespace:       String: avoid customer app name collisions
    #
    # RETURNS:
    #   The result of the change request, including the request ID for
    #   polling the request status
    #
    def modify_application(app_name, namespace, new_public_hostname)
      # delete the CNAME record for the application in the domain
      fqdn = "#{app_name}-#{namespace}.#{@domain_suffix}"

      # Get the record you mean to delete.
      # We need the TTL and value to delete it.
      record = get_record(fqdn)

      # If record is nil, then we're done.  Raise an exception for trying?
      return if record == nil
      ttl = record[:ttl]
      old_public_hostname = record[:resource_records][0][:value]

      update = {
        :comment => "Update an application record for #{fqdn}",
        :changes => [change_record("DELETE", fqdn, @ttl, old_public_hostname),
                     change_record("CREATE", fqdn, @ttl, new_public_hostname)]
      }
      

      res = r53.change_resource_record_sets({
                                              :hosted_zone_id => @aws_hosted_zone_id,
                                              :change_batch => update
                                            })
    end

    #
    # execute queued changes (noop)
    #
    # INPUTS: None
    #
    # RETURNS: Nil
    #
    def publish
    end


    #
    # end communication with the service (noop)
    #
    # INPUTS: None
    #
    # RETURNS: Nil
    #    
    def close
    end
    

    private

    # create a Route53 communications client.
    def r53()
      AWS::Route53.new(:access_key_id => @aws_access_key_id,
                       :secret_access_key => @aws_access_key).client
    end

    #
    # Create an Route53 change record data structure
    #
    # INPUTS:
    #   action: String  - "CREATE" or "DELETE"
    #   fqdn:   String  - the fully qualified domain name to be changed
    #   ttl:    Integer - Time To Live (seconds)
    #   value:  String  - The value to be assigned to the record
    #
    # RETURNS:
    #   Hash: a structure suitable for use as a change record in
    #         an AWS update request.
    #
    def change_record(action, fqdn, ttl, value)
      # the CNAME values must be quoted
      {
        :action => action,
        :resource_record_set => {
          :name => fqdn,
          :type => "CNAME",
          :ttl => ttl,
          :resource_records => [{:value => value}],
        }
      }
    end
        
    # 
    # Retrieve a record from the AWS Route53 service
    # 
    # INPUTS:
    #   fqdn: String - The fully qualified domain name of the record to get
    #
    # RETURNS:
    #   Hash: a single AWS Route 53 resource record hash
    #
    def get_record(fqdn)
      # Request a single record "starting with" the desired record.
      reply = r53.list_resource_record_sets(
                :hosted_zone_id => @aws_hosted_zone_id,
                :start_record_name => fqdn,
                :max_items => 1
            )

      # If the returned record name matches exactly, return it.
      # record fqdn are returned with the trailing anchor (.)
      return nil if not reply

      # Check if we found it exactly
      res = reply[:resource_record_sets][0]
      return nil if not res

      return res if res[:name] == fqdn + "."

      # If not, then you got nothing or a record which didn't match.
      nil
    end

  end
end
