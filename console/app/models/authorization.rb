#
# The REST API model object representing a user authorization
#
class Authorization < RestApi::Base
  schema do
    string :id, :token, :note, :identity, :oauth_client_id
    integer :expires_in, :expires_in_seconds
    datetime :created_at
  end

  singular_resource

  belongs_to :user

  def created_at
    DateTime.parse(attributes[:created_at]) rescue nil
  end

  def sso?
    scopes.include?('sso')
  end

  def expired?
    not (expires_in_seconds > 0)
  end
  def expires_at
    created_at + expires_in.seconds
  end

  def scopes
    s = (attributes[:scopes] || attributes[:scope] || '')
    s = s.split(/[,\s]/) if s.is_a?(String)
    Array(s)
  end
  def scopes=(a)
    self.scope = a
  end
  def scope=(scopes)
    attributes.delete :scopes
    attributes[:scope] = Array(scopes).join(',')
  end

  def oauth_scopes
    s = (attributes[:oauth_scopes] || attributes[:oauth_scope] || '')
    s = s.split(/[,\s]/) if s.is_a?(String)
    Array(s)
  end
  def oauth_scopes=(a)
    self.oauth_scope = a
  end
  def oauth_scope=(oauth_scopes)
    attributes.delete :oauth_scopes
    attributes[:oauth_scope] = Array(oauth_scopes).join(',')
  end  

  def reuse!
    attributes[:reuse] = true
  end

  def to_headers
    {'Authorization' => "Bearer #{token}"}
  end

  def self.destroy(id_or_token, options={})
    Authorization.new({:id => id_or_token, :as => options[:as]}, true).destroy
  end

  def self.destroy_all(options={})
    prefix_options, query_options = split_options(options[:params])
    connection(options).delete(collection_path(prefix_options, query_options))
  end
end
