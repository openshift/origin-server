require 'dnsruby'

##
# @api REST
class DnsResolvableController < BaseController
  ##
  # Support API to check if application DNS entry is available
  #
  # URL: /domains/:domain_id/applications/:application_id/dns_resolvable
  #
  # Action: GET
  #
  # @return [RestReply<Boolean>] Returns true when DNS entry is resolvable
  def show
    domain_id = params[:domain_id].downcase if params[:domain_id]
    id = params[:application_id].downcase if params[:application_id]

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "DNS_RESOLVABLE")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: id)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found", 101, "DNS_RESOLVABLE")
    end

    name = "#{application.name}-#{domain.namespace}.#{Rails.configuration.openshift[:domain_suffix]}" 
    begin
     nameservers = NameServerCache.get_name_servers
    rescue Exception => e
      return render_error(:not_found, "Could not resolve DNS #{name}: #{e.message}", 170, "DNS_RESOLVABLE")
    end
    
    dns = Dnsruby::Resolver.new(:nameserver => nameservers[rand(nameservers.length)]) if nameservers
    begin
      dns.query(name, Dnsruby::Types.A)
      render_success(:ok, "boolean", true, "DNS_RESOLVABLE", "Resolved DNS #{name}")
    rescue Exception => e
      render_error(:not_found, "Could not resolve DNS #{name}: #{e.message}", 170, "DNS_RESOLVABLE")
    end
  end
end
