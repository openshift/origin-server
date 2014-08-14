class Region < RestApi::Base
  schema do
    string :id, :name, :description
    boolean :default, :allow_selection
  end

  allow_anonymous

end
