class AddSslCertOp < PendingAppOp

  field :fqdn, type: String
  field :ssl_certificate, type: String
  field :private_key, type: String
  field :pass_phrase, type: Array
  field :gear_id, type: String

  def execute
    result_io = ResultIO.new
    gear = get_gear()
    result_io = gear.add_ssl_cert(ssl_certificate, private_key, fqdn, pass_phrase) unless gear.removed

    # set the cert properties in the alias only if they haven't been added already
    a = application.aliases.find_by(fqdn: fqdn)
    unless a.has_private_ssl_certificate
      a.has_private_ssl_certificate = true
      a.certificate_added_at = Time.now
      application.save!
    end

    result_io
  end

  def rollback
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
