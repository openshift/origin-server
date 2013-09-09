class UserSessionSweeper < ActiveModel::Observer
  observe User, Application, Domain, Cartridge

  def self.before(controller)
    self.user_changes = false
    true
  end
  def self.after(controller)
    if self.user_changes?
      controller.session[:caps] = nil
      Rails.logger.debug "Session capabilities are reset"
    end
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
