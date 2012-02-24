#
# The REST API model object representing the domain, which may contain multiple applications.
#
class Domain < RestApi::Base
  schema do
    string :namespace
    string :ssh #deprecated, remove
  end

  custom_id :namespace, true
  mutable_attribute :ssh #deprecated, remove
  # TODO: Bug 789752: Make namespace consistent with other usages
  alias_attribute :name, :namespace

  has_many :applications
  def applications
    @applications ||= Application.find :all, { :params => { :domain_name => self.name }, :as => as }
  end
  #FIXME should have an observer pattern that clears cached associations on reload
  def reload
    @applications = nil
    super
  end

  belongs_to :user
  def user
    User.find :one, :as => as
  end

  def find_application(name)
    Application.find name, { :params => { :domain_name => self.name }, :as => as}
  end

  def destroy_recursive
    connection.delete(element_path({:force => true}.merge(prefix_options)), self.class.headers)
  end
end
