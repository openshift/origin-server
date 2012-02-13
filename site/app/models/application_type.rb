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
      :id => 'empty',
      :name => 'Simple Application',
      :categories => [:empty],
      :description => 'This application is created without cartridges.  The application cannot be deployed until you add a cartridge.'
    },
    {
      :id => 'php-5.3',
      :name => 'PHP 5.3',
      :version => '5.3.2',
      :categories => [:framework],
      :description => 'PHP is a widely-used general-purpose scripting language that is especially suited for Web development and can be embedded into HTML.',
      :website => 'http://www.php.net',
      :provides => [
        'Apache configured with mod_php',
        'PHP script directory for you to check PHP files into'
      ]
    },
    {
      :id => 'rails32',
      :name => 'Ruby on Rails 3.2',
      :categories => [:popular_future],
      :description => 'One of the most popular web frameworks in recent memory, Ruby on Rails provides a complete solution for building rich websites while getting out of your way.',
      :website => 'http://www.rubyonrails.org'
    },
    {
      :id => 'python-2.6',
      :name => 'Python 2.6 with WSGI',
      :version => 'Python 2.6.6 / WSGI 3.2',
      :categories => [:framework],
      :description => 'WSGI is the common interface between Python and web servers.  This can be used to create web applications with TurboGears, Django, and other WSGI-compatible frameworks.',
      :website => 'http://rack.rubyforge.org/'
    },
    {
      :id => 'perl-5.10',
      :name => 'Perl 5.10 with mod_perl',
      :version => 'Perl 5.10 / mod_perl 2.0.4',
      :categories => [:framework],
      :description => 'mod_perl brings together the full power of the Perl programming language and the Apache HTTP server. You can use Perl to manage Apache, respond to requests for web pages and much more.',
      :website => 'http://perl.apache.org/start/index.html'
    },
    {
      :id => 'ruby-1.8',
      :name => 'Ruby 1.8.7 with Rack',
      :version => 'Ruby 1.8.7 / Rack 1.1',
      :categories => [:framework],
      :description => 'Supports Rack applications with Phusion Passenger. Use this application to create Sinatra, Ruby on Rails, or other Rack-compatible Ruby web application frameworks.',
      :website => 'http://rack.rubyforge.org/'
    },
    {
      :id => 'jbossas-7.0',
      :name => 'JBoss Application Server 7.0',
      :version => 'JBoss AS 7.0.2.Final',
      :license => 'GNU LPGL 2.1',
      :license_url => 'http://www.gnu.org/licenses/lgpl-2.1-standalone.html',
      :categories => [:framework],
      :description => 'JBoss Application Server 7.0 is the open solution for enterprise Java.',
      :website => 'http://www.jboss.org/jbossas'
    },
    {
      :id => 'raw-0.1',
      :name => 'Do-It-Yourself',
#      :version => '1.0',
      :categories => [:framework, :experimental],
      :description => 'The Do-It-Yourself (DIY) application type is a blank slate for trying unsupported languages, frameworks, and middleware on OpenShift. See the community site for examples of bringing your favorite framework to OpenShift.'
      #:website => 'http://perl.apache.org/start/index.html'
    }
  ].map { |t| ApplicationType.new t }

  class << self
    def find_empty
      @default_types.find { |type| type.id == 'empty' } or raise NotFound
    end

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

