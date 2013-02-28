class DomainSessionSweeper < ActiveModel::Observer
  observe Domain

  def self.before(controller)
    self.domain_changes = false
    true
  end
  def self.after(controller)
    if self.domain_changes?
      controller.session[:domain] = nil
      Rails.logger.debug "Session domain is reset"
    end
  end

  def self.domain_changes?
    Thread.current[:domain_sweeper]
  end
  def self.domain_changes=(bool)
    Thread.current[:domain_sweeper] = bool
  end

  def changed
    self.class.domain_changes = true
  end

  def after_save(domain)
    changed
  end
  def after_destroy(domain)
    changed
  end
end
