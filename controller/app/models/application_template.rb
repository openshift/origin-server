class ApplicationTemplate
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :display_name, type: String
  field :descriptor_yaml, type: String
  field :git_url, type: String
  field :tags, type: Array, default: []
  field :gear_cost, type: Integer, default: 1
  field :template_metadata, type: Hash, default: {}
end