class SystemSshKey
  include Mongoid::Document
  embedded_in :domain, class_name: Domain.name

  field :name, :type => String
  field :type, :type => String, :default => "ssh-rsa"
  field :content, :type => String
  
  validates :name, :presence => true, :format => /\A[A-Za-z0-9]+\z/, :length => { :maximum => 256, :minimum => 1 }
  validates :type, :presence => true, :format => /\A(ssh-rsa|ssh-dss)\z/
  validates :content, :presence => true, :format => /\A[A-Za-z0-9\+\/=]+\z/  
end
