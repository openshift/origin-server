class ReplaceAllSshKeysOpGroup < PendingAppOpGroup

  field :keys_attrs, type: Array, default: []

  def elaborate(app)
    if keys_attrs
      app.gears.each do |gear|
        pending_ops.push(ReplaceAllSshKeysOp.new(gear_id: gear.id.to_s, keys_attrs: keys_attrs))
      end
    end
  end

end
