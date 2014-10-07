
class UnsetHaOp < PendingAppOp
  def execute
    self.application.ha = false
    self.application.save!
  end

  def rollback
    self.application.ha = true
    self.application.save!
  end
end
