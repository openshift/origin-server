#
# The REST API model object representing a domain name alias to an application.
#
class Alias < RestApi::Base

  singular_resource

  schema do
    string :id
    string :has_private_ssl_certificate
    string :certificate_added_at
    string :ssl_certificate
    string :private_key
    string :pass_phrase
  end

  custom_id :id

  # Optional accessors for form upload
  attr_accessor :certificate_file, :certificate_chain_file, :certificate_private_key_file

  belongs_to :application

  alias_attribute :name, :id
  alias_attribute :certificate, :ssl_certificate
  alias_attribute :certificate_chain, :ssl_certificate_chain
  alias_attribute :certificate_private_key, :private_key
  alias_attribute :certificate_pass_phrase, :pass_phrase

  validates_presence_of :certificate_file, :message => "Required if a certificate chain or private key file is selected.", :if => lambda { |a| a.certificate_chain_file.present? || a.certificate_private_key_file.present? }
  validates :certificate_file, :length => {:minimum => 1, :message => "SSL certificate file was empty."}, :allow_nil => true

  validates_presence_of :certificate_private_key_file, :message => "Required if a certificate or certificate chain file is selected.", :if => lambda { |a| a.certificate_chain_file.present? || a.certificate_file.present? }
  validates :certificate_private_key_file, :length => {:minimum => 1, :message => "Certificate private key file was empty."}, :allow_nil => true

  validates :certificate_chain_file, :length => {:minimum => 1, :message => "SSL certificate chain file was empty."}, :allow_nil => true

  def certificate_file=(value)
    @certificate_file = value.present? ? File.read(value.path) : nil;
    recreate_ssl_certificate
  end

  def certificate_chain_file=(value)
    @certificate_chain_file = value.present? ? File.read(value.path) : nil;
    recreate_ssl_certificate
  end

  def recreate_ssl_certificate
    if !@certificate_file.nil?
      self.ssl_certificate = @certificate_file
      if !@certificate_chain_file.nil?
        self.ssl_certificate.strip!
        self.ssl_certificate << "\n" << @certificate_chain_file.strip
      end
    end
    normalize_ssl_certificate
  end

  def normalize_ssl_certificate
    if self.ssl_certificate.present?
      ssl_certificate_universal_encoding = self.ssl_certificate.encode(self.ssl_certificate.encoding, :universal_newline => true)
      ssl_certificate_crlf_newline = ssl_certificate_universal_encoding.encode(self.ssl_certificate.encoding, :crlf_newline => true)
      self.ssl_certificate = ssl_certificate_crlf_newline
    end
  end

  def certificate_private_key_file=(value)
    self.private_key = @certificate_private_key_file = value.present? ? File.read(value.path) : nil;
  end

  def has_private_ssl_certificate?
    has_private_ssl_certificate
  end

  def certificate_added_at
    super ? Date.parse(super) : super
  end

  def web_uri(scheme=nil)
    URI::Generic.new(scheme, nil, id, nil, nil, nil, nil, nil, nil)
  end

  def <=>(a)
    return self.name <=> a.name
  end

end
