class ApplicationType
  include ActiveModel::Conversion
  include ActiveModel::MassAssignmentSecurity
  include RestApi::Cacheable
  extend ActiveModel::Naming

  PROTECTED_TAGS = [:new, :premium, :blacklist, :featured, :custom]
  def self.user_tags(tags)
    tags - PROTECTED_TAGS
  end

  class NotFound < RestApi::ResourceNotFound
    def initialize(id, response=nil)
      super(ApplicationType.model_name, id, response)
    end
  end

  CartridgeSpecInvalid = Class.new(StandardError)

  attr_accessor :id, :display_name, :version, :description
  attr_accessor :cartridges, :initial_git_url, :initial_git_branch, :cartridges_spec
  attr_accessor :website, :license, :license_url
  attr_accessor :tags, :learn_more_url
  attr_accessor :help_topics
  attr_accessor :priority
  attr_accessor :scalable
  alias_method :scalable?, :scalable
  attr_accessor :provider
  attr_accessor :source
  attr_accessor :usage_rates

  attr_accessible :initial_git_url, :cartridges, :initial_git_branch, :scalable
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

  def usage_rates?
    !(usage_rates.nil? || usage_rates.empty?)
  end

  def cartridge_specs
    begin
      s = (@cartridges_spec || cartridges || [])
      if s.is_a? Array
        s
      else
        s = s.strip
        if s[0] == '['
          ActiveSupport::JSON.decode(s).map{ |s| s.is_a?(Hash) ? s['name'] : s }
        else
          s.split(',').map(&:strip)
        end
      end
    rescue
      raise ApplicationType::CartridgeSpecInvalid, $!, $@
    end
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
    when :cartridge; -2
    else; 0
    end
  end

  def support_type
    provider or tags.include?(:community) ? :community : :openshift
  end

  def automatic_updates?
    cartridge? && !tags.include?(:community)
  end

  def cartridge?; source == :cartridge; end
  def quickstart?; source == :quickstart; end
  def custom?; id == 'custom'; end

  def matching_cartridges
    self.class.matching_cartridges(cartridge_specs)
  end

  def >>(app)
    app.cartridges = cartridges.map{ |s| to_cart(s) } if cartridges.present?
    app.initial_git_url = initial_git_url if initial_git_url
    app.initial_git_branch = initial_git_branch if initial_git_branch
    app
  end

  def to_cart(c)
    if c.is_a?(String) && (c.start_with? 'http://' or c.start_with? 'https://')
      CartridgeType.for_url(c)
    else
      c
    end
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

  def self.all(*arguments)
    find(:all, *arguments)
  end

  def self.search(query, opts={})
    find(:all, {:search => query}.merge(opts))
  end

  def self.tagged(tag, opts={})
    find(:all, {:tag => tag}.merge(opts))
  end

  def self.find(*arguments)
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

  def self.matching_cartridges(cartridge_specs)
    valid, invalid = {}, []
    Array(cartridge_specs).uniq.each do |c|
      if c.start_with? 'http://' or c.start_with? 'https://'
        valid[c] = [CartridgeType.for_url(c)]
      elsif (matches = CartridgeType.cached.matches(c)).present?
        valid[c] = matches
      else
        invalid << c
      end
    end
    [valid, invalid]
  end

  def self.custom(attrs={})
    attrs = {} if attrs.nil? || attrs.is_a?(String)
    attrs[:scalable] = true unless attrs.has_key?(:scalable)
    new(:id => 'custom', :display_name => 'From Scratch').assign_attributes(attrs)
  end

  protected
    def self.find_single(id, *arguments)
      case (match = /^([^!]+)!(.+)/.match(id) || [])[1]
      when 'quickstart'; from_quickstart(Quickstart.find match[2])
      when 'cart'; from_cartridge_type(CartridgeType.cached.find match[2])
      else raise NotFound.new(id)
      end
      #find_every(*arguments).find{ |t| t.id == id } or raise NotFound, id
    end

    def self.find_every(opts={})
      source = opts[:source].nil? ? nil : Array(opts[:source])

      types = []
      case
      when opts[:search]
        query = opts[:search].downcase
        types.concat CartridgeType.cached.standalone
        types.keep_if &LOCAL_SEARCH.curry[query]
        types.concat Quickstart.search(query) rescue handle_error($!)
      when opts[:tag]
        tag = opts[:tag].to_sym rescue (return [])
        types.concat CartridgeType.cached.standalone
        if tag != :cartridge
          types.keep_if &TAG_FILTER.curry[[tag]]
          types.concat Quickstart.search(tag.to_s) rescue handle_error($!)
        end
      else
        types.concat CartridgeType.cached.standalone
        types.concat Quickstart.cached.promoted rescue handle_error($!)
      end
      raise "nil types" unless types

      types.select do |t|
        not (t.tags.include?(:blacklist) or (Rails.env.production? and t.tags.include?(:in_development)))
      end.map do |t|
        case t
        when CartridgeType; from_cartridge_type(t)
        when Quickstart; from_quickstart(t)
        end
      end
    end

    def self.from_cartridge_type(type)
      attrs = {:id => "cart!#{type.name}", :source => :cartridge}
      [:display_name, :tags, :description, :website, :version, :license, :license_url, :help_topics, :priority, :scalable, :usage_rates].each do |m|
        attrs[m] = type.send(m)
      end
      attrs[:cartridges] = [type.name]

      new(attrs, type.persisted?)
    end
    def self.from_quickstart(type)
      attrs = { :id => "quickstart!#{type.id}", :source => :quickstart }
      [:display_name, :tags, :description, :website, :initial_git_url, :initial_git_branch, :cartridges_spec, :priority, :scalable, :learn_more_url, :provider].each do |m|
        attrs[m] = type.send(m)
      end

      new(attrs, type.persisted?)
    end

    def self.handle_error(e)
      Rails.logger.error "Unable to process source data: #{e.message}\n#{e.backtrace.join("\n  ")}"
      nil
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
