class ApplicationTemplate < RestApi::Base
  allow_anonymous

  schema do
    string :descriptor_yaml, :display_name
  end

  custom_id :name

  [:description, :website, :version, :git_url, :git_project_url].each do |s|
    define_attribute_method s
    define_method s do
      metadata.attributes[s]
    end
  end
  {:name => 'Name', :provides => 'Requires'}.each_pair do |s,v|
    define_attribute_method s
    define_method s do
      descriptor[v]
    end
  end

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

  def provides
    Array(super)
  end

  def template
    self
  end

  def credentials
    creds = metadata.attributes[:credentials]
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

  #def attribute(s)
  #  return get_metadata(s) if [:description, :website, :version, :git_url, :git_project_url].include?(s.to_sym)
  #  attr = {:name => 'Name', :provides => 'Requires'}[s.to_sym]
  #  return get_descriptor(attr) if attr
  #  super
  #end

  #def method_missing(method, *args, &block)
    # These attributes are defined in the metadata
  #  metadata = [:description, :website, :version, :git_url, :git_project_url]

    # These attributes are defined in the descriptor
  #  descriptor_map = 

    # See if we know about the missing method
  #  case method
  #  when *metadata
  ##    get_metadata(method)
  #  when *descriptor_map.keys
  #    get_descriptor(descriptor_map[method])
  #  else
  #    super
  #  end
  #end

  def to_application_type
    attrs = { :id => name, :name => display_name }

    [:tags, :description, :website, :version, :template, :provides].each do |m|
      attrs[m] = send(m)
    end

    ApplicationType.new attrs
  end

  cache_find_method :single
  cache_find_method :every
end
