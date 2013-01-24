require 'rubygems'
require 'json'
require 'active_model'

module OpenShift
  class Model
    extend ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::Serializers::JSON
    self.include_root_in_json = false
    include ActiveModel::Serializers::Xml
    include ActiveModel::AttributeMethods
    include ActiveModel::Observing    
    
    def attributes
      a = {}
      self.instance_variable_names.each do |name|
        a[name[1..-1]] = self.instance_variable_get(name)
      end
      a
    end
    
    def to_xml(options = {})
      to_xml_opts = {:skip_types => true}
      to_xml_opts.merge!(options.slice(:builder, :skip_instruct))
      to_xml_opts[:root] = options[:tag_name] || self.class.name.underscore.gsub("_","-")
      self.attributes.to_xml(to_xml_opts)
    end
  end
end