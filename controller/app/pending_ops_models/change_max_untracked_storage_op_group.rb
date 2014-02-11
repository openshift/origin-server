class ChangeMaxUntrackedStorageOpGroup < PendingAppOpGroup

  field :old_untracked, type: Integer
  field :new_untracked, type: Integer

  def elaborate(app)
    ops = app.calculate_change_max_untracked_storage_ops(old_untracked || 0, new_untracked || 0)
    self.pending_ops.concat(ops)
    self.save! if app.persisted?
  end

end
