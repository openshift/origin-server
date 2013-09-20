class ReplaceAllSshKeysOpGroup < PendingAppOpGroup

  field :keys_attrs, type: Array, default: []

  def elaborate(app)
    if keys_attrs
      app.group_instances.each do |group_instance|
        group_instance_id = group_instance._id.to_s
        group_instance.gears.each do |gear|
          gear_id = gear._id.to_s
          pending_ops.push(ReplaceAllSshKeysOp.new(keys_attrs: keys_attrs))
        end
      end
    end
  end

end
