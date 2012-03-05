class CartridgeType
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

  def initialize(attributes={})
    attributes.each do |name,value|
      send("#{name}=", value)
    end
  end

  def persisted?
    true
  end

  @default_types = [
    {
      :id => 'mongodb-2.0',
      :name => 'MongoDB NoSQL Database 2.0',
      :version => 'MongoDB 2.0',
      :license => 'ASL 2.0 and AGPLv3',
      :license_url => 'http://www.mongodb.org/display/DOCS/Licensing',
      :categories => [:cartridge],
      :description => 'MongoDB is a scalable, high-performance, open source NoSQL database.',
      :website => 'http://www.mongodb.org/',
      :help_topics => {
      }
    },
    {
      :id => 'mysql-5.1',
      :name => 'MySQL Database 5.1',
      :version => 'MySQL 5.1',
      :license => 'GPLv2 with exceptions',
      :license_url => 'http://www.mysql.com/about/legal/licensing/index.html',
      :categories => [:cartridge],
      :description => 'MySQL is a multi-user, multi-threaded SQL database server.',
      :website => 'http://www.mysql.com/',
      :help_topics => {
      }
    }
  ].map { |t| CartridgeType.new t }

  class << self
    def find(*arguments)
      option = arguments.slice(0)
      case option
      when String
        @default_types.find { |type| type.id == option } or raise NotFound
      when :all
        Array.new(@default_types)
      when Symbol
        @default_types.find { |type| type.categories.include? option }
      else
        raise "Unsupported scope"
      end
    end
  end
end
