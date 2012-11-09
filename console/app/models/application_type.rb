class ApplicationType
  include ActiveModel::Conversion
  include ActiveModel::MassAssignmentSecurity
  include RestApi::Cacheable
  extend ActiveModel::Naming

  PROTECTED_TAGS = [:new, :premium, :blacklist, :featured]
  def self.user_tags(tags)
    tags - PROTECTED_TAGS
  end

  class NotFound < RestApi::ResourceNotFound
    def initialize(id, response=nil)
      super(ApplicationType.model_name, id, response)
    end
  end

  attr_accessor :id, :display_name, :version, :description
  attr_accessor :cartridges, :initial_git_url, :initial_git_branch
  attr_accessor :template # DEPRECATED
  attr_accessor :website, :license, :license_url
  attr_accessor :tags, :learn_more_url
  attr_accessor :help_topics
  attr_accessor :priority
  attr_accessor :scalable
  alias_method :scalable?, :scalable
  attr_accessor :source

  attr_accessible :initial_git_url, :cartridges, :initial_git_branch

  alias_attribute :categories, :tags

  def initialize(attributes={}, persisted=false)
    attributes.each do |name,value|
      send("#{name}=", value)
    end
    @persisted = persisted
  end

  def persisted?
    @persisted
  end

  def new?
    tags.include?(:new)
  end

  def to_params
    persisted? ? {:id => id} : [:cartridges, :initial_git_url, :initial_git_branch].inject({}){ |h, s| h[s] = send(s); h }
  end

  def cartridges=(cartridges)
    @cartridges = Array(cartridges)
  end

  def <=>(other)
    return 0 if id == other.id
    c = source_priority - other.source_priority
    return c unless c == 0
    c = priority - other.priority
    return c unless c == 0
    display_name <=> other.display_name
  end

  def tags
    @tags || []
  end

  def priority
    @priority || 0
  end

  def source_priority
    case source
    when :template; -1
    when :cartridge; -2
    else; 0
    end
  end

  def cartridge?; source == :cartridge; end
  def template?; source == :template; end
  def quickstart?; source == :quickstart; end

  def matching_cartridges
    self.class.matching_cartridges(cartridges)
  end

  def >>(app)
    if template
      app.template = template.uuid
    else
      app.cartridges = cartridges if cartridges.present?
      app.initial_git_url = initial_git_url if initial_git_url
      app.initial_git_branch = initial_git_branch if initial_git_branch
    end
    app
  end

  #
  # Default mass assignment support
  #
  def assign_attributes(values, options = {})
    sanitize_for_mass_assignment(values, options[:as]).each do |k, v|
      send("#{k}=", v)
    end
    self
  end

  cache_find_method :every

  class << self
    def all(*arguments)
      find(:all, *arguments)
    end

    def search(query, opts={})
      find(:all, {:search => query}.merge(opts))
    end

    def tagged(tag, opts={})
      find(:all, {:tag => tag}.merge(opts))
    end

    def find(*arguments)
      option = arguments.shift
      case option
      when String
        find_single(option, *arguments)
      when :all
        find_every(*arguments)
      when Symbol
        find_every(*arguments).select { |t| t.tags.include? option }
      else
        raise "Unsupported scope"
      end
    end

    def matching_cartridges(cartridges)
      valid, invalid = {}, []
      Array(cartridges).uniq.each do |c|
        if (matches = CartridgeType.cached.matches(c)).present?
          valid[c] = matches
        else
          invalid << c
        end
      end
      [valid, invalid]
    end

    def custom(attrs={})
      attrs = {} if attrs.nil? || attrs.is_a?(String)
      new(:id => 'custom', :display_name => 'From Scratch').assign_attributes(attrs)
    end

    protected
      def find_single(id, *arguments)
        case (match = /^([^!]+)!(.+)/.match(id) || [])[1]
        when 'community'; from_quickstart(Quickstart.find match[2])
        when 'cart'; from_cartridge_type(CartridgeType.cached.find match[2])
        when 'template'; from_application_template(ApplicationTemplate.cached.find match[2])
        else raise NotFound.new(id)
        end
        #find_every(*arguments).find{ |t| t.id == id } or raise NotFound, id
      end

      def find_every(opts={})
        source = opts[:source].nil? ? nil : Array(opts[:source])

        types = []
        case
        when opts[:search]
          query = opts[:search].downcase
          types.concat CartridgeType.cached.standalone
          types.concat ApplicationTemplate.cached.all
          types.keep_if &LOCAL_SEARCH.curry[query]
          types.concat Quickstart.search(query)
        when opts[:tag]
          tag = opts[:tag].to_sym rescue (return [])
          types.concat CartridgeType.cached.standalone
          types.concat ApplicationTemplate.cached.all unless tag == :cartridge
          types.keep_if &TAG_FILTER.curry[[tag]]
          types.concat Quickstart.search([tag.to_s]) unless tag == :cartridge
        else
          types.concat CartridgeType.cached.standalone
          types.concat ApplicationTemplate.cached.all
          types.concat Quickstart.cached.promoted
        end
        raise "nil types" unless types

        types.select do |t|
          not (t.tags.include?(:blacklist) or (Rails.env.production? and t.tags.include?(:in_development)))
        end.map do |t|
          case t
          when ApplicationTemplate; from_application_template(t)
          when CartridgeType; from_cartridge_type(t)
          when Quickstart; from_quickstart(t)
          end
        end
      end

      def from_cartridge_type(type)
        attrs = {:id => "cart!#{type.name}", :source => :cartridge}
        [:display_name, :tags, :description, :website, :version, :license, :license_url, :help_topics, :priority, :scalable].each do |m|
          attrs[m] = type.send(m)
        end
        attrs[:cartridges] = [type.name]

        new(attrs, type.persisted?)
      end
      def from_application_template(type)
        attrs = { :id => "template!#{type.name}", :source => :template }
        [:display_name, :tags, :description, :website, :version, :template, :cartridges, :scalable, :initial_git_url, :initial_git_branch].each do |m|
          attrs[m] = type.send(m)
        end

        new(attrs, type.persisted?)
      end
      def from_quickstart(type)
        attrs = { :id => "community!#{type.id}", :source => :quickstart }
        [:display_name, :tags, :description, :website, :initial_git_url, :initial_git_branch, :cartridges, :priority, :scalable, :learn_more_url].each do |m|
          attrs[m] = type.send(m)
        end

        new(attrs, type.persisted?)
      end
  end

  protected
    LOCAL_SEARCH = lambda do |query, t|
      t.description.downcase.include?(query) or
        t.display_name.downcase.include?(query) or
        (t.tags.include?(query.to_sym) rescue false)
    end
    TAG_FILTER = lambda do |query, t|
      (t.tags & query) == query
    end
end
