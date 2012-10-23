require 'validators/key_validator'

class Key < OpenShift::Model
  attr_accessor :name, :type, :content
  include ActiveModel::Validations

  VALID_SSH_KEY_TYPES = ['ssh-rsa', 'ssh-dss', 'ecdsa-sha2-nistp256-cert-v01@openssh.com', 'ecdsa-sha2-nistp384-cert-v01@openssh.com',
                         'ecdsa-sha2-nistp521-cert-v01@openssh.com', 'ssh-rsa-cert-v01@openssh.com', 'ssh-dss-cert-v01@openssh.com',
                         'ssh-rsa-cert-v00@openssh.com', 'ssh-dss-cert-v00@openssh.com', 'ecdsa-sha2-nistp256', 'ecdsa-sha2-nistp384', 'ecdsa-sha2-nistp521']
  DEFAULT_SSH_KEY_TYPE = "ssh-rsa" unless defined? DEFAULT_SSH_KEY_TYPE
  DEFAULT_SSH_KEY_NAME = "default" unless defined? DEFAULT_SSH_KEY_NAME

  validates_with KeyValidator

  def initialize(name, type, content)
    self.name = name
    self.type = type
    self.content = content
  end
end
