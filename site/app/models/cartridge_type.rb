class CartridgeType < RestApi::Base
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  class NotFound < StandardError
  end

  schema do
    string :name, :type
  end

  attr_accessor :name, :id, :type, :version, :description
  attr_accessor :provides
  attr_accessor :cartridge
  attr_accessor :website, :license, :license_url
  attr_accessor :categories, :learn_more_url
  attr_accessor :help_topics

  self.prefix = "#{RestApi::Base.site.path}/cartridges/embedded"

  def initialize(attributes={})
    attributes.each do |name,value|
      send("#{name}=", value)
    end
    super
  end

  def persisted?
    true
  end

  # FIXME: Right now the restapi only gives the name (id) of the available
  #        types so we supliment it with info here.  Ideally the REST API
  #        or some common lookaside cache populates this data
  @type_map = {
    "mongodb-2.0" =>
    {
      :id => 'mongodb-2.0',
      :name => 'MongoDB NoSQL Database 2.0',
      :type => 'embedded',
      :version => 'MongoDB 2.0',
      :license => 'ASL 2.0 and AGPLv3',
      :license_url => 'http://www.mongodb.org/display/DOCS/Licensing',
      :categories => [:cartridge],
      :description => 'MongoDB is a scalable, high-performance, open source NoSQL database.',
      :website => 'http://www.mongodb.org/',
      :help_topics => {
      }
    },
    "mysql-5.1" =>
    {
      :id => 'mysql-5.1',
      :name => 'MySQL Database 5.1',
      :type => 'embedded',
      :version => 'MySQL 5.1',
      :license => 'GPLv2 with exceptions',
      :license_url => 'http://www.mysql.com/about/legal/licensing/index.html',
      :categories => [:embedded],
      :description => 'MySQL is a multi-user, multi-threaded SQL database server.',
      :website => 'http://www.mysql.com/',
      :help_topics => {
      }
    }
  }

  class << self
    def find(*arguments)
      scope   = arguments.slice!(0)
      options = arguments.slice!(0) || {}

      path = "#{prefix}.json"
      rest_types = format.decode(connection(options).get(path, headers).body)

      default_types = rest_types.map do |t|
        name = t['name']

        if !@type_map[name].nil?
          CartridgeType.new(@type_map[name])
        else
          CartridgeType.new({:id => name, :name => name, :categories => [t['type']]})
        end
      end

      case scope
      when String
        default_types.find { |type| type.id == scope } or raise NotFound
      when :all
        default_types
      when Symbol
        default_types.find { |type| type.categories.include? scope }
      else
        raise "Unsupported scope"
      end
    end
  end
end
