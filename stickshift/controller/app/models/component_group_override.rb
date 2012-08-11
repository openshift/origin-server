class ComponentGroupOverride
  include Mongoid::Document
  embedded_in :application, class_name: Application.name
  embeds_many :comps, :class_name => ComponentRef.name
end
