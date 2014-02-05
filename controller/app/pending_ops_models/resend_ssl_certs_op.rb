class ResendSslCertsOp < PendingAppOp

  field :fqdns, type: Array
  field :gear_id, type: String

  def execute
    result_io = ResultIO.new
    gear = get_gear()
    unless gear.removed
      # get all the SSL certs from the HAProxy DNS gear 
      haproxy_gears = application.gears.select { |g| gear.component_instances.select { |ci| ci.get_cartridge.is_web_proxy? }.present? }
      dns_haproxy_gear = haproxy_gears.select { |g| g.app_dns }.first
      certs = dns_haproxy_gear.get_all_ssl_certs()

      # send the SSL certs for the specified aliases to the gear 
      certs.each do |cert_info|
        if fqdns.include? cert_info[2]
          result_io.append gear.add_ssl_cert(cert_info[0], cert_info[1], cert_info[2])
        end
      end 
    end
    result_io
  end

  def rollback
    result_io = ResultIO.new
    gear = get_gear()
    unless gear.removed
      fqdns.each do |fqdn|
        result_io.append gear.remove_ssl_cert(fqdn)
      end
    end
    result_io
  end

end
