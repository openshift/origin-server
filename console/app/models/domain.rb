#
# The REST API model object representing the domain, which may contain multiple applications.
#
class Domain < RestApi::Base
  schema do
    string :id
    string :suffix
  end

  on_exit_code(158, :on_invalid => (Domain::UserAlreadyHasDomain = Class.new(ActiveResource::ResourceInvalid)))
  on_exit_code(103, :on_invalid => (Domain::AlreadyExists = Class.new(ActiveResource::ResourceInvalid)))

  custom_id :id, true # domain id is mutable, FIXME rename method to primary_key
  alias_attribute :name, :id

  singular_resource

  has_many :applications
  def applications
    @applications ||= Application.find :all, { :params => { :domain_id => self.id }, :as => as }
  end
  def find_application(name, opts={})
    Application.find name, { :params => { :domain_id => self.id }, :as => as}.deep_merge!(opts)
  end

  #FIXME should have an observer pattern that clears cached associations on reload
  def reload
    @applications = nil
    super
  end

  def user
    User.find :one, :as => as
  end

  def destroy_recursive
    connection.delete(element_path({:force => true}.merge(prefix_options)), self.class.headers)
  end

  # FIXME: Temporary until multiple domains are supported
  def self.find_one(options)
    domain = first(options)
    raise RestApi::ResourceNotFound.new(model_name, nil) if domain.nil?
    domain
  end
end
