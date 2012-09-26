class SshkeySessionSweeper < ActiveModel::Observer
  observe Key

  def self.before(controller)
    self.sshkey_changes = false
    true
  end
  def self.after(controller)
    controller.session[:has_sshkey] = nil if self.sshkey_changes?
  end

  def self.sshkey_changes?
    Thread.current[:sshkey_sweeper]
  end
  def self.sshkey_changes=(bool)
    Thread.current[:sshkey_sweeper] = bool
  end

  def changed
    self.class.sshkey_changes = true
  end

  def after_save(key)
    changed
  end
  def after_destroy(key)
    changed
  end
end
