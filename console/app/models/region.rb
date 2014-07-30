class Region < RestApi::Base
  schema do
    string :id, :name, :description
    boolean :default
  end

  allow_anonymous

end
