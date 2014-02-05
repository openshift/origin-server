class RemoveSslCertOpGroup < PendingAppOpGroup

  field :fqdn, type: String

  def elaborate(app)
    app.gears.each do |gear|
      if app.scalable
        if gear.component_instances.select { |ci| ci.get_cartridge.is_web_proxy? }.present?
          pending_ops.push RemoveSslCertOp.new(gear_id: gear.id.to_s, fqdn: fqdn)
        end
      else
        pending_ops.push RemoveSslCertOp.new(gear_id: gear.id.to_s, fqdn: fqdn)
      end
    end

    pending_ops.push NotifySslCertRemoveOp.new(fqdn: fqdn)
  end

end
