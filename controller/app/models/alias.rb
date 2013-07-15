##
# @api model
# Represents a DNS CName alias associated with the application
#
# @!attribute [r] fqdn
#   @return [String] Fully qualified domain name of the alias
# @!attribute [r] has_private_ssl_certificate
#   @return [Boolean] True if there is a custom SSL certificate associated with this alias
# @!attribute [r] certificate_added_at
#   @return [Date] Timestamp of when the custom SSL certificate was added
class Alias
  include Mongoid::Document
  embedded_in :application

  self.field :fqdn, type: String
  self.field :has_private_ssl_certificate, type: Boolean, default: false
  self.field :certificate_added_at,type: Date, default: nil

  ##
  # Returns the alias object as a hash
  # @return [Hash]
  def to_hash
    {"fqdn" => fqdn, "has_private_ssl_certificate" => has_private_ssl_certificate, "certificate_added_at" => certificate_added_at}
  end
end
