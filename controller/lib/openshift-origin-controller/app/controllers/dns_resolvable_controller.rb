require 'rubygems'
require 'dnsruby'

class DnsResolvableController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  
  # GET /domains/<id>
  def show
    domain_id = params[:domain_id]
    id = params[:application_id]
    
    domain = Domain.get(@cloud_user, domain_id)
    return render_error(:not_found, "Domain #{domain_id} not found", 127,
                        "DNS_RESOLVABLE") if !domain || !domain.hasAccess?(@cloud_user)

    application = Application.find(@cloud_user,id)
    return render_error(:not_found, "Application '#{id}' not found", 101,
                        "DNS_RESOLVABLE") unless application
                        
    name = "#{application.name}-#{application.domain.namespace}.#{Rails.configuration.ss[:domain_suffix]}" 
    nameservers = NameServerCache.get_name_servers             
    
    dns = Dnsruby::Resolver.new(:nameserver => nameservers[rand(nameservers.length)])
    begin
      dns.query(name, Dnsruby::Types.A)
      render_success(:ok, "boolean", true, "DNS_RESOLVABLE", "Resolved DNS #{name}")
    rescue 
      render_error(:not_found, "Could not resolve DNS #{name}", 168, "DNS_RESOLVABLE")
    end
  end
end