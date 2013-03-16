class Alias
  include Mongoid::Document
  embedded_in :application
   
  self.field :fqdn, type: String
  self.field :has_private_ssl_certificate, type: Boolean, default: false
  self.field :certificate_added_at,type: Date, default: nil
  
  def to_hash
    {"fqdn" => fqdn, "has_private_ssl_certificate" => has_private_ssl_certificate, "certificate_added_at" => certificate_added_at}
  end
end
