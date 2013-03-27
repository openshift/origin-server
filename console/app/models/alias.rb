#
# The REST API model object representing a domain name alias to an application.
#
class Alias < RestApi::Base

  schema do
    string :id
    string :has_private_ssl_certificate
    string :certificate_added_at
    string :ssl_certificate
    string :private_key
    string :pass_phrase
  end

  custom_id :id

  attr_accessor :certificate_file, :certificate_chain_file, :certificate_private_key_file

  belongs_to :application

  alias_attribute :name, :id
  alias_attribute :certificate, :ssl_certificate
  alias_attribute :certificate_chain, :ssl_certificate_chain
  alias_attribute :certificate_private_key, :private_key
  alias_attribute :certificate_pass_phrase, :pass_phrase

  def normalize_certificate_content!
    self.ssl_certificate = File.read(@certificate_file.path) if !@certificate_file.nil?
    self.ssl_certificate << "\n" << File.read(@certificate_chain_file.path) if !@certificate_file.nil? && !@certificate_chain_file.nil?
    self.private_key = File.read(@certificate_private_key_file.path) if !@certificate_private_key_file.nil?
    @certificate_file, @certificate_chain_file, @certificate_private_key_file = nil, nil, nil
  end

  def has_private_ssl_certificate?
    has_private_ssl_certificate
  end

  def certificate_added_at
    super ? Date.parse(super) : super
  end

  def <=>(a)
    return self.name <=> a.name
  end

end
