class Alias
  include Mongoid::Document
  embedded_in :application
   
  self.field :fqdn, type: String
  self.field :has_private_certificate, type: Boolean, default: false
  
  def to_hash
    {"fqdn" => fqdn, "has_private_certificate" => has_private_certificate}
  end
end
