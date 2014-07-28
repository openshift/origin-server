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

  singular_resource

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
  attr_accessor :valid_gear_sizes

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

  def suggest_name
    if name.present?
      name_prefix
    elsif url.present?
      url_suggested_name
    end
  end

  def to_param
    name || url
  end

  def url_suggested_name
    uri = URI.parse(url)
    name = uri.fragment
    name = Rack::Utils.parse_nested_query(uri.query)['name'] if name.blank? && uri.query
    name.presence
  rescue
    nil
  end

  def url_basename
    uri = URI.parse(url)
    name = url_suggested_name
    name = File.basename(uri.path) if name.blank? && uri.path.present? && uri.path != '/'
    name.presence || url
  rescue
    url
  end

  def support_type
    @support_type ||=
      if vendor = @attributes[:maintained_by].presence
        vendor == 'redhat' ? :openshift : :community
      else
        :community
      end
  end

  def automatic_updates?
    v = @attributes[:automatic_updates]
    if v.nil?
      v = !(tags.include?('no_updates') || custom?)
    end
    v
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

  def service?
    tags.include?(:service)
  end
  def plugin?
    tags.include?(:plugin)
  end
  def database?
    tags.include?(:database)
  end
  def web_framework?
    tags.include?(:web_framework)
  end
  def builder?
    tags.include?(:ci_builder)
  end
  def jenkins_client?
    builder? && name_prefix == 'jenkins-client'
  end
  def haproxy_balancer?
    tags.include?(:web_proxy) && name_prefix == 'haproxy'
  end
  def external?
    tags.include?(:external)
  end

  def conflicts
    @conflicts || []
  end

  def requires
    @requires || []
  end

  # Override to make sure bad urls don't get used in web UI
  def help_topics
    (@help_topics || {}).inject({}) do |topics, (k,v)|
      url = CartridgeType.normalize_url(v)
      topics[k] = url if url
      topics
    end
  end

  def url
    CartridgeType.normalize_url(super)
  end

  def website
    CartridgeType.normalize_url(@website)
  end

  def license_url
    CartridgeType.normalize_url(@license_url)
  end

  def learn_more_url
    CartridgeType.normalize_url(@learn_more_url)
  end

  def priority
    @priority || 0
  end

  def usage_rates
    @usage_rates || []
  end

  def valid_gear_sizes?
    !@valid_gear_sizes.nil?
  end

  def valid_gear_sizes
    valid_gear_sizes? ? Array(@valid_gear_sizes).map(&:to_sym) : nil
  end

  def scalable
    @attributes['supported_scales_to'] != @attributes['supported_scales_from']
  end

  alias_method :scalable?, :scalable

  def name_parts
    @name_parts ||= begin
      if match = /\A(.+)-(\d+(?:\.\d+)*)\Z/.match(name)
        n, v = match.values_at(1,2)
        [n, v.split('.').map(&:to_i)]
      else
        [name, '0']
      end
    end
  end

  def name_prefix
    name_parts[0]
  end
  def name_version
    name_parts[1]
  end

  def newer_than(other)
    other.name_prefix == name_prefix && (other.name_version <=> name_version) == -1
  end

  def ==(o)
    to_param == o.to_param
  end

  def hash
    to_param.hash
  end

  def <=>(other)
    return 0 if name == other.name
    return 0 if url && url == other.url
    c = self.class.tag_compare(tags, other.tags)
    return c unless c == 0
    c = priority - other.priority
    return c unless c == 0
    display_name <=> other.display_name
  end

  def self.normalize_url(url, default_scheme='http')
    return nil if url.blank?
    scheme = URI.parse(url).scheme
    return nil if scheme =~ /^javascript/i
    return "#{default_scheme}://#{url}" if scheme.blank? and default_scheme
    return url
  rescue
    nil
  end

  def self.for_url(url)
    new({:url => normalize_url(url)}, true)
  end

  def self.embedded(*arguments)
    all(*arguments).select(&:embedded?)
  end

  def self.standalone(*arguments)
    all(*arguments).select(&:standalone?)
  end

  def self.suggest!(*arguments)
    limit = arguments.pop if arguments.last.is_a? Numeric
    source = arguments.shift if arguments.length > 1
    arr = []
    arr =
      if source.is_a?(Array)
        source.delete_if{ |c| arr << c if arguments.any?{ |sym| c.send(sym) } }
        arr
      else
        send(source || :all).select{ |c| arguments.any?{ |sym| c.send(sym) } }
      end
    arr.delete_if{ |c| arr.any?{ |other| other.newer_than(c) } } # remove older versions of the same cart
    arr.sort!
    arr = arr.first(limit) if limit
    arr
  end

  def self.suggest_useful!(app, carts, *filters)
    carts = carts.select{ filters.any?{ |sym| c.send(sym) } } if filters.present?
    requires = app.cartridges.inject([]){ |arr, cart| arr.concat(carts.select{ |c| c.requires.any?{ |r| r.include?(cart.name) } }) }
    carts.delete_if{ |c| requires.include?(c) }
    requires
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
