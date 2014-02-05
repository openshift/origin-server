class RemoveSslCertOp < PendingAppOp

  field :fqdn, type: String
  field :gear_id, type: String

  def execute
    result_io = ResultIO.new
    gear = get_gear()
    result_io = gear.remove_ssl_cert(fqdn) unless gear.removed
    begin
      a = application.aliases.find_by(fqdn: fqdn)

      # remove the cert properties from the alias only if they haven't been removed  already
      if a.has_private_ssl_certificate
        a.has_private_ssl_certificate = false
        a.certificate_added_at = nil
        application.save!
      end
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if alias is not found
    end
    result_io
  end

end
