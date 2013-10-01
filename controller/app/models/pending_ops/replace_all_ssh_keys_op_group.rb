class ReplaceAllSshKeysOpGroup < PendingAppOpGroup

  field :keys_attrs, type: Array, default: []

  def elaborate(app)
    if keys_attrs
      app.group_instances.each do |group_instance|
        group_instance.gears.each do |gear|
          pending_ops.push(ReplaceAllSshKeysOp.new(group_instance_id: group_instance.id.to_s, gear_id: gear.id.to_s, keys_attrs: keys_attrs))
        end
      end
    end
  end

end
