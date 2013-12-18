class UpdateClusterOpGroup < PendingAppOpGroup

  def elaborate(app)
    pending_ops.push UpdateClusterOp.new
  end

end
