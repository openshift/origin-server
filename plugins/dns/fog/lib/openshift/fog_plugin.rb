#
# Make OpenShift DNS updates using Fog
#
require 'rubygems'
require 'fog'

module OpenShift

  class FogPlugin < OpenShift::DnsService
    @oo_dns_provider = OpenShift::FogPlugin

    attr_reader :config, :zone

    def initialize(access_info = nil)
      access_info = Rails.application.config.dns unless !access_info.nil?
      @zone = access_info[:zone]
      @config = access_info.clone
      @config.delete(:zone)
    end

    def register_application(app_name, namespace, public_hostname)
      fqdn = "#{app_name}-#{namespace}.#{@zone}"
      zone = fog.zones.find {|zone| zone.domain == @zone}
      zone.records.create({
        :name => fqdn,
        :type => 'CNAME',
        :value => public_hostname
      })
    end

    def deregister_application(app_name, namespace)
      fqdn = "#{app_name}-#{namespace}.#{@zone}"
      zone = fog.zones.find {|zone| zone.domain == @zone}
      record = zone.records.find {|record| record.name == fqdn}
      record.destroy unless record.nil?
    end

    def modify_application(app_name, namespace, new_public_hostname)
      fqdn = "#{app_name}-#{namespace}.#{@zone}"
      zone = fog.zones.find {|zone| zone.domain == @zone}
      record = zone.records.find {|record| record.name == fqdn}
      record.name = fqdn
      record.value = new_public_hostname
      record.save
    end

    def publish
    end

    def close
    end

    private

    def fog
      Fog::DNS.new(@config)
    end

  end
end

