#
# The REST API model object representing the domain, which may contain multiple applications.
#
class Domain < RestApi::Base
  schema do
    string :id
    string :suffix
  end

  on_exit_code(102, :on_invalid => (Domain::UserAlreadyHasDomain = Class.new(ActiveResource::ResourceInvalid)))
  on_exit_code(158, :on_invalid =>  Domain::UserAlreadyHasDomain)
  on_exit_code(103, :on_invalid => (Domain::AlreadyExists = Class.new(ActiveResource::ResourceInvalid)))

  custom_id :id, true # domain id is mutable, FIXME rename method to primary_key
  alias_attribute :name, :id

  has_many :applications
  def applications
    @applications ||= Application.find :all, { :params => { :domain_id => self.id }, :as => as }
  end
  def find_application(name)
    Application.find name, { :params => { :domain_id => self.id }, :as => as}
  end

  #FIXME should have an observer pattern that clears cached associations on reload
  def reload
    @applications = nil
    super
  end

  #belongs_to :user
  def user
    User.find :one, :as => as
  end

  def destroy_recursive
    connection.delete(element_path({:force => true}.merge(prefix_options)), self.class.headers)
  end

  #def save(*args)
    # FIXME: We do this since we do not yet handle multiple domains in the
    #        UI.  This mitigates a race condition where multiple domains
    #        can be created if there is no domains registered yet but does
    #        not fix it.
  #  first_domain = Domain.first :as => @as
  #  unless first_domain.nil?
  #    if first_domain != self && @update_id.nil?
  #      errors.add(:name, "User already has a domain associated. Go back to accounts to modify.")
  #      return false
  #    end
  #  end

  #  super
  #end

  # FIXME: Temporary until multiple domains are supported
  def self.find_one(options)
    domain = first(options)
    raise ActiveResource::ResourceNotFound, :domain if domain.nil?
    domain
  end
end
