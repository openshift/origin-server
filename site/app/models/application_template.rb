class ApplicationTemplate < RestApi::Base
  include RestApi::Cacheable

  singleton

  custom_id :name

  def descriptor
    @descriptor ||= YAML.load(descriptor_yaml) || {}
  end

  def display_name
    attributes['display_name'] || name
  end
  def tags
    @tags ||= super.map{|t| t.to_sym} << :template
  end
  alias_method :categories, :tags

  def template
    self
  end

  def credentials
    creds = get_metadata(:credentials)
    creds.map{|x| x.attributes.to_hash } unless creds.nil?
  end

  def credentials_message
    creds = credentials
    return if credentials.empty?

    str =  "Your application contains pre-configured accounts, here are their credentials. " +
           "You may want to change them as soon as possible.\n"

    credentials.each do |cred|
      str << "\n"
      [:username, :password].each do |type|
        str << "%s: %s\n" % [type.to_s.upcase,cred[type.to_s]]
      end
    end

    str
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
