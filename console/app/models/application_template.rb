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
    return if creds.blank?

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

  def scalable
    @scalable ||= tags.include?(:not_scalable) ? false : true
  ensure
    Rails.logger.debug("Handling #{self.name} app template as non-scalable") unless @scalable
  end
  alias_method :scalable?, :scalable

  def cartridges
    @cartridges ||= descriptor['Requires'] || []
  end

  alias_method :initial_git_url, :git_url
  def initial_git_branch
    nil
  end

  cache_find_method :single, lambda{ |*args| [:template, :find, :by_id, args.shift] }
  cache_find_method :every

  protected
    def self.find_single(s, opts=nil)
      all(opts).find{ |t| t.name == s }
    end

    def self.disabled?
      !RestApi.info.link('LIST_TEMPLATES') rescue true
    end
end
