class ComponentRef
  include Mongoid::Document
  embedded_in :application, class_name: Application.name
  
  field :cart, :type => String
  field :comp, :type => String  
end
