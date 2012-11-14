class UserSessionSweeper < ActiveModel::Observer
  observe User, Application, Domain

  def self.before(controller)
    self.user_changes = false
    true
  end
  def self.after(controller)
    controller.session[:user_capabilities] = nil if self.user_changes?
  end

  def self.user_changes?
    Thread.current[:user_sweeper]
  end
  def self.user_changes=(bool)
    Thread.current[:user_sweeper] = bool
  end

  def changed
    self.class.user_changes = true
  end

  def after_save(user)
    changed
  end
  def after_destroy(user)
    changed
  end
end
