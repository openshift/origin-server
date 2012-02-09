class ApplicationType
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :id, :name, :website, :version, :description, :license, :categories

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
      :id => 'php5.3',
      :name => 'PHP 5.3',
      :categories => [:framework],
      :description => 'PHP is a fast, flexible, easy to learn web framework based on Perl.',
      :website => 'http://www.php.net'
    },
    {
      :id => 'rails32',
      :name => 'Ruby on Rails 3.2',
      :categories => [:popular],
      :description => 'One of the most popular web frameworks in recent memory, Ruby on Rails provides a complete solution for building rich websites while getting out of your way.',
      :website => 'http://www.rubyonrails.org'
    },
    {
      :id => 'jbossa7.1',
      :name => 'JBoss Web Application 7.1',
      :categories => [:framework],
      :description => 'JBoss Application Server 7.1 is the open solution for enterprise Java.',
      :website => 'http://www.jboss.org'
    }
  ].map { |t| ApplicationType.new t }

  class << self
    def find(*arguments)
      option = arguments.slice(0)
      case option
      when String
        @default_types.find { |type| type.id == option }
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

