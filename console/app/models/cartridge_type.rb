class CartridgeType < RestApi::Base
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  include Comparable

  schema do
    string :name, 'type'
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

  self.element_name = 'cartridges'

  def initialize(attributes={},persisted=true)
    attributes = attributes.with_indifferent_access
    name = attributes['name'].presence || attributes[:name].presence
    defaults = self.class.defaults(name)
    defaults.keys.each{ |k| attributes.delete(k) if attributes[k].blank? }
    attributes.reverse_merge!(defaults)
    super attributes, true
  end

  def type
    (@attributes[:type] || :embedded).to_sym
  end

  def embedded?;    type == :embedded; end
  def standalone?;  type == :standalone; end

  def display_name
    @display_name || name
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

  def persisted?
    true
  end

  def <=>(other)
    return 0 if name == other.name
    c = priority - other.priority
    return c unless c == 0
    c = self.class.tag_compare(tags, other.tags)
    return c unless c == 0
    display_name <=> other.display_name
  end

  def to_application_type
    attrs = {:id => name, :name => display_name}
    [:version, :license, :license_url,
     :tags, :description, :website,
     :help_topics, :priority].each do |m|
      attrs[m] = send(m)
    end
    ApplicationType.new attrs
  end

  def self.embedded(*arguments)
    all(*arguments).select(&:embedded?)
  end

  def self.standalone(*arguments)
    all(*arguments).select(&:standalone?)
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
      all(options).find{ |t| t.to_param == scope } or new(:name => scope, :as => options[:as])
    end

    def self.type_map
      Rails.application.config.cartridge_types_by_name
    end

    def self.defaults(name)
      attrs = type_map[name.to_s]
      Rails.logger.warn "> The cartridge type '#{name}' is not defined - no metadata is available." unless attrs
      attrs || {}
    end

end
