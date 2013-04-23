class CartridgeType < RestApi::Base
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  include Comparable

  schema do
    string :name, 'type', :url
    string :tags
  end

  custom_id :name

  allow_anonymous

  attr_accessor :version, :description
  attr_accessor :display_name
  attr_accessor :provides
  attr_accessor :cartridge
  attr_accessor :website, :license, :license_url
  attr_accessor :learn_more_url
  attr_accessor :conflicts, :requires
  attr_accessor :help_topics
  attr_accessor :priority
  attr_accessor :usage_rates

  has_many :properties, :class_name => as_indifferent_hash
  has_many :usage_rate, :class_name => as_indifferent_hash

  self.element_name = 'cartridges'

  def initialize(attributes={},persisted=false)
    attributes = attributes.with_indifferent_access
    name = attributes['name'].presence || attributes[:name].presence
    if name
      defaults = self.class.defaults(name)
      defaults.keys.each{ |k| attributes.delete(k) if attributes[k].blank? }
      attributes.reverse_merge!(defaults)
    end
    super attributes, persisted
  end

  def type
    (@attributes[:type] || :embedded).to_sym
  end

  def embedded?;    type == :embedded; end
  def standalone?;  type == :standalone; end
  def custom?;      url.present?; end

  def display_name
    @display_name ||= url_basename || name
  end

  def to_param
    url || name
  end

  def url_basename
    uri = URI.parse(url)
    name = uri.fragment
    name = Rack::Utils.parse_nested_query(uri.query)['name'] if name.blank? && uri.query
    name = File.basename(uri.path) if name.blank? && uri.path.present? && uri.path != '/'
    name.presence || url
  rescue 
    url
  end

  # Legacy, use #tags
  def categories
    @categories || []
  end
  def categories=(cats)
    @categories = cats.map{ |c| c.to_sym }.compact.uniq
  end

  def tags
    @tags ||= (super || [] rescue []).map{ |t| t.to_sym}.concat(categories).compact
  end
  def tags=(tags)
    @tags = nil
    @attributes[:tags] = tags
  end

  def conflicts
    @conflicts || []
  end

  def requires
    @requires || []
  end

  def help_topics
    @help_topics || {}
  end

  def priority
    @priority || 0
  end

  def usage_rates
    @usage_rates || []
  end

  def scalable
    self.attributes['supported_scales_to'] != self.attributes['supported_scales_from']
  end
  alias_method :scalable?, :scalable

  def <=>(other)
    return 0 if name == other.name
    c = self.class.tag_compare(tags, other.tags)
    return c unless c == 0
    c = priority - other.priority
    return c unless c == 0
    display_name <=> other.display_name
  end

  def self.for_url(url)
    new({:url => url}, true)
  end

  def self.embedded(*arguments)
    all(*arguments).select(&:embedded?)
  end

  def self.standalone(*arguments)
    all(*arguments).select(&:standalone?)
  end

  def self.matches(s, opts=nil)
    every = all(opts)
    s.split('|').map{ |s| s.gsub('*','') }.map do |s|
      Array(every.find{ |t| t.name == s } || every.select do |t|
        t.name.include?(s)
      end)
    end.flatten.uniq
  end

  cache_find_method :every

  def self.tag_compare(a,b)
    [:web_framework, :database].each do |t|
      if a.include? t
        return -1 unless b.include? t
      else
        return 1 if b.include? t
      end
    end
    0
  end

  class Property < RestApi::Base
  end

  protected
    def self.find_single(scope, options)
      all(options).find{ |t| t.to_param == scope } or raise RestApi::ResourceNotFound.new(CartridgeType.name, scope)
    end

    def self.type_map
      Rails.application.config.cartridge_types_by_name
    end

    def self.defaults(name)
      type_map[name.to_s] || {}
    end
end
