class Region < RestApi::Base
  schema do
    string :id, :name
    boolean :default
  end

  allow_anonymous

end
