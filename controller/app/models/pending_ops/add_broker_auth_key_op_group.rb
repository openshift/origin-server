class AddBrokerAuthKeyOpGroup < PendingAppOpGroup

  field :iv, type: String
  field :token, type: String

  def elaborate(app)
    ops = []
    app.group_instances.each do |group_instance|
      group_instance.gears.each do |gear|
        ops.push(AddBrokerAuthKeyOp.new(iv: iv, token: token, group_instance_id: group_instance.id.to_s, gear_id: gear.id.to_s))
      end
    end
    pending_ops.push(*ops)
  end
end
