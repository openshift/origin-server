class EnvironmentVariable < RestApi::Base

  singular_resource

  schema do
    string :name, :value
  end
  custom_id :name

  belongs_to :application

  def <=>(a)
    return self.name <=> a.name
  end

end
