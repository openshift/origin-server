require 'rubygems'
require 'dnsruby'

class DnsResolvableController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
  # GET /domains/[domain_id]/applications/<id>/dns_resolvable
  def show
    domain_id = params[:domain_id]
    id = params[:application_id]
    
    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "DNS_RESOLVABLE")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound      
      return render_error(:not_found, "Application '#{id}' not found", 101, "DNS_RESOLVABLE")
    end
                        
    name = "#{application.name}-#{domain.namespace}.#{Rails.configuration.openshift[:domain_suffix]}" 
    nameservers = NameServerCache.get_name_servers             
    
    dns = Dnsruby::Resolver.new(:nameserver => nameservers[rand(nameservers.length)])
    begin
      dns.query(name, Dnsruby::Types.A)
      render_success(:ok, "boolean", true, "DNS_RESOLVABLE", "Resolved DNS #{name}")
    rescue 
      render_error(:not_found, "Could not resolve DNS #{name}", 170, "DNS_RESOLVABLE")
    end
  end
end
