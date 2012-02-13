#
# The REST API model object representing the domain, which may contain multiple applications.
#
class Domain < RestApi::Base
  schema do
    string :namespace
    string :ssh
  end

  custom_id :namespace, true
  # TODO: Bug 789752: Make namespace consistent with other usages
  alias_attribute :name, :namespace

  has_many :applications
  def applications
    Application.find :all, { :params => { :domain_name => name }, :as => as }
  end

  belongs_to :user
  def user
    User.find :one, :as => as
  end

  def destroy_recursive
    connection.delete(element_path({:force => true}.merge(prefix_options)), self.class.headers)
  end
end
