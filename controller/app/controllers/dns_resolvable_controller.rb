require 'dnsruby'

##
# @api REST
class DnsResolvableController < BaseController
  before_filter :get_application
  ##
  # Support API to check if application DNS entry is available
  #
  # @return [RestReply<Boolean>] Returns true when DNS entry is resolvable
  def show
    name = @application.fqdn
    begin
     nameservers = NameServerCache.get_name_servers
    rescue Exception => e
      return render_error(:not_found, "Could not resolve DNS #{name}: #{e.message}", 170, "DNS_RESOLVABLE")
    end

    dns = Dnsruby::Resolver.new(:nameserver => nameservers[rand(nameservers.length)]) if nameservers
    begin
      dns.query(name, Dnsruby::Types.A)
      render_success(:ok, "boolean", true, "Resolved DNS #{name}")
    rescue Exception => e
      render_error(:not_found, "Could not resolve DNS #{name}: #{e.message}", 170)
    end
  end

  protected
    def action_log_tag
      "DNS_RESOLVABLE"
    end
end
