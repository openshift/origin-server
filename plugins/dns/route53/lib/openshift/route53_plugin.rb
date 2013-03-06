#
# Make OpenShift updates to Amazon Web Services Route53 DNS service
#
# http://docs.aws.amazon.com/AWSRubySDK/latest/frames.html
# http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/Route53/Client.html
#
require 'rubygems'
require 'aws-sdk'

module OpenShift

  # OpenShift DNS plugin to interact with dynamic DNS using AWS Route53
  # @see https://aws.amazon.com/route53/ Amazon Route53
  #
  # The object can be configured either by providing the access_info
  # parameter or by pulling the settings from the Rails.application.config
  # object (if it exists).
  #
  # When pulling from the Rails configuration this plugin expects to find
  # the domain_suffix in 
  #   Rails.application.config.openshift[:domain_suffix]
  # and the rest of the parameters in a hash at
  #   Rails.application.config.dns
  #
  # @example Route53 plugin configuration hash
  #   {:aws_hosted_zone_id => "HOSTEDZONEIDSTRING",
  #    :aws_access_key_id => "ACCESSKEYIDSTRING",
  #    :aws_access_key    => "AWSSECRETKEYSTRING",
  #    # only when configuring with explicit argument list
  #    :domain_suffix => "suffix for application domain names"
  #    }
  #
  # @!attribute [r] aws_hosted_zone_id
  #   @return [String] the hosted zone ID of your dynamic zone
  # @!attribute [r] aws_access_key_id
  #   @return [String] your account ID string
  # @!attribute [r] aws_access_key
  #   @return [String] your secret access key string
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

    # Publish an application - create DNS record
    #
    # @param [String] app_name
    #   The name of the application to publish
    # @param [String] namespace
    #   The namespace which contains the application
    # @param [String] public_hostname
    #   The name of the location where the application resides
    # @return [Object]
    #   The result of the change request, including the request ID for
    #   polling the request status
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

    # Publish an application - create DNS record
    #
    # @param [String] app_name
    #   The name of the application to publish
    # @param [String] namespace
    #   The namespace which contains the application
    # @param [String] public_hostname
    #   The name of the location where the application resides
    # @return [Object]
    #   The result of the change request, including the request ID for
    #   polling the request status
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

    # Publish an application - create DNS record
    #
    # @param [String] app_name
    #   The name of the application to publish
    # @param [String] namespace
    #   The namespace which contains the application
    # @param [String] public_hostname
    #   The name of the location where the application resides
    # @return [Object]
    #   The result of the change request, including the request ID for
    #   polling the request status
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


    # send any queued requests to the update server
    # @return [nil]
    def publish
    end

    # close any persistent connection to the update server
    # @return [nil]
    def close
    end
    
    private

    # create a Route53 communications client.
    #
    # @return [AWS::Route53::Client]
    def r53()
      AWS::Route53.new(:access_key_id => @aws_access_key_id,
                       :secret_access_key => @aws_access_key).client
    end

    # Create an Route53 change record data structure
    #
    # @param [String] action "CREATE" or "DELETE"
    # @param [String] fqdn the fully qualified domain name of the record
    # @param [FixNum] ttl "time to live" in seconds
    # @param [String] value the fully qualified domain name of the app host
    # @return [Hash] a data structure suitable for use in a Route53 change
    #   request
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
        
    # Retrieve a record from the AWS Route53 service
    # 
    # @param [String] fqdn The fully qualified domain name of an application
    # @return [nil|Hash] Return nil or a hash containing the requested record
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
