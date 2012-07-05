class ApplicationType
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  class NotFound < StandardError
  end

  attr_accessor :id, :name, :version, :description
  attr_accessor :provides
  attr_accessor :cartridge
  attr_accessor :website, :license, :license_url
  attr_accessor :categories, :learn_more_url
  attr_accessor :help_topics
  attr_accessor :blocks
  attr_accessor :template

  def initialize(attributes={})
    attributes.each do |name,value|
      send("#{name}=", value)
    end
  end

  def persisted?
    true
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
        find_every(*arguments).select { |t| t.categories.include? option }
      else
        raise "Unsupported scope"
      end
    end
    protected
      def find_single(id, *arguments)
        find_every(*arguments).find{ |t| t.id == id } or raise NotFound, id
      end
      def find_every(opts={})
        cartridges = CartridgeType.cached.standalone(:as => opts[:as]).select do |t|
          not t.categories.include?(:blacklist)
        end.map do |t|
          t.to_application_type
        end

        templates = ApplicationTemplate.cached.all(:as => opts[:as]).select do |t|
          not t.categories.include?(:blacklist)
        end.map do |t|
          t.to_application_type
        end

        templates.concat(cartridges)
      end
  end
end
