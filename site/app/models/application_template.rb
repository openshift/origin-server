class ApplicationTemplate < RestApi::Base
  include RestApi::Cacheable

  singleton

  custom_id :name

  attr_accessor :categories

  def descriptor
    YAML.load(descriptor_yaml)
  end

  def categories
    tags.map{|t| t.to_sym} << :template
  end

  def template
    self
  end

  def method_missing(method, *args, &block)
    # These attributes are defined in the metadata
    metadata = [:description, :website, :version, :git_url, :git_project_url]

    # These attributes are defined in the descriptor
    descriptor_map = {
      :name => 'Name',
      :provides => 'Requires'
    }

    # See if we know about the missing method
    case method
    when *metadata
      get_metadata(method)
    when *descriptor_map.keys
      get_descriptor(descriptor_map[method])
    else
      super
    end
  end

  def to_application_type
    attrs = { :id => name, :name => display_name }

    [:categories, :description, :website, :version, :template, :provides].each do |m|
      attrs[m] = send(m)
    end

    ApplicationType.new attrs
  end

  cache_method :all, [name, :all], :before => lambda { |e| e.each { |c| c.as = nil } }

  private
    def get_metadata(name)
      metadata.attributes[name]
    end

    def get_descriptor(name)
      descriptor[name]
    end
end
