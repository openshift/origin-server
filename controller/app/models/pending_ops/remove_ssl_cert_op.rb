class RemoveSslCertOp < PendingAppOp

  field :fqdn, type: String
  field :group_instance_id, type: String
  field :gear_id, type: String

  def execute
    result_io = ResultIO.new
    gear = get_gear()
    result_io = gear.remove_ssl_cert(fqdn) unless gear.removed
    begin
      a = pending_app_op_group.application.aliases.find_by(fqdn: fqdn)
      a.has_private_ssl_certificate = false
      a.certificate_added_at = nil
      pending_app_op_group.application.save
    rescue Mongoid::Errors::DocumentNotFound
      # ignore if alias is not found
    end
    result_io
  end

end
