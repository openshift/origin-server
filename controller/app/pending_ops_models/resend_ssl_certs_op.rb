class ResendSslCertsOp < PendingAppOp

  field :gear_id, type: String
  field :ssl_certs, type: Array

  def execute
    result_io = ResultIO.new
    gear = get_gear()
    unless gear.removed
      # send the specified SSL certs to the gear
      ssl_certs.each do |cert_info|
        result_io.append gear.add_ssl_cert(cert_info[0], cert_info[1], cert_info[2])
      end 
    end
    result_io
  end

  def rollback
    result_io = nil
    unless skip_rollback
      gear = get_gear()
      unless gear.removed
        ssl_certs.each do |cert_info|
          result_io.append gear.remove_ssl_cert(cert_info[2])
        end
      end
    end
    result_io
  end

end
