class ApplicationType
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  class NotFound < RestApi::ResourceNotFound
    def initialize(id, response=nil)
      super(ApplicationType.model_name, id, response)
    end
  end

  attr_accessor :id, :name, :version, :description
  attr_accessor :provides
  attr_accessor :cartridge
  attr_accessor :website, :license, :license_url
  attr_accessor :tags, :learn_more_url
  attr_accessor :help_topics
  attr_accessor :priority
  attr_accessor :template

  alias_attribute :categories, :tags
  alias_attribute :display_name, :name

  def initialize(attributes={})
    attributes.each do |name,value|
      send("#{name}=", value)
    end
  end

  def persisted?
    true
  end

  def <=>(other)
    return 0 if id == other.id
    c = priority - other.priority
    return c unless c == 0
    display_name <=> other.display_name
  end

  def priority
    @priority || 0
  end

  def provided_cartridges
    @provided_cartridges ||= expand_provided_cartridges
  end

  def scalable?
    @scalable ||= CartridgeType.cached.find(self.id).attributes.has_key?('scaling_info')
  end

  class << self
    def all(*arguments)
      find(:all, *arguments)
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
    protected
      def find_single(id, *arguments)
        find_every(*arguments).find{ |t| t.id == id } or raise NotFound, id
      end
      def find_every(opts={})
        cartridges = CartridgeType.cached.standalone.map(&:to_application_type)
        templates = ApplicationTemplate.cached.all.map(&:to_application_type)

        templates.concat(cartridges).select do |t|
          not (t.tags.include?(:blacklist) or (Rails.env.production? and t.tags.include?(:in_development)))
        end
      end
  end

  protected
    def expand_provided_cartridges
      cartridge_list = []
      if self.provides
        self.provides.each do |item_id|
          next unless cartridge_type = CartridgeType.cached.find(item_id)
          cartridge_list << cartridge_type
        end
      end
      cartridge_list
    end
end
