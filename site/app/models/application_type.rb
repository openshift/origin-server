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

  @special_types_array = [
  # These should not be directly creatable
    {
      :id   => 'haproxy-depricated-1.4',
      :name => "Scaled application",
      :version => '1.4',
      :categories => [],
      # Right now, nothing should be able to be embedded in a scaling app
      :blocks => [
        'mysql-5.1',
        "mongodb-2.0" ,
        "cron-1.4" ,
        "postgresql-8.4" ,
        "10gen-mms-agent-0.1" ,
        "phpmyadmin-3.4" ,
        "metrics-0.1" ,
        "phpmoadmin-1.0" ,
        "rockmongo-1.1" ,
        "jenkins-client-1.4" ,
      ]
    },
    # hardcoded
  ]

  @default_types = @special_types_array.map { |t| new t }

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
          t.categories.include?(:framework) and not t.categories.include?(:blacklist)
        end.map do |t|
          t.to_application_type
        end

        templates = ApplicationTemplate.cached.all(:as => opts[:as]).select do |t|
          t.categories.include?(:framework) and not t.categories.include?(:blacklist)
        end.map do |t|
          t.to_application_type
        end

        templates.concat(cartridges).concat(@default_types)
      end
  end
end
