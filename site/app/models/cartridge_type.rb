class CartridgeType < RestApi::Base
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  schema do
    string :name, 'type'
  end

  custom_id :name

  # provided by client
  attr_accessor :version, :description
  attr_accessor :display_name
  attr_accessor :provides
  attr_accessor :cartridge
  attr_accessor :website, :license, :license_url
  attr_accessor :categories, :learn_more_url
  attr_accessor :help_topics

  self.element_name = 'cartridges'
  #self.prefix = "#{RestApi::Base.prefix}cartridges"

  def initialize(attributes={},persisted=true)
    attr = attributes.reverse_merge!(self.class.defaults(attributes['name'].presence || attributes[:name].presence))
    super attr, true
  end

  def type
    (e = @attributes[:type]).is_a?(String) ? [e.to_sym] : e
  end

  def persisted?
    true
  end

  @type_map = {
    "mongodb-2.0" =>
    {
      :name => 'mongodb-2.0',
      :display_name => 'MongoDB NoSQL Database 2.0',
      :type => 'embedded',
      :version => 'MongoDB 2.0',
      :license => 'ASL 2.0 and AGPLv3',
      :license_url => 'http://www.mongodb.org/display/DOCS/Licensing',
      :categories => [:cartridge],
      :description => 'MongoDB is a scalable, high-performance, open source NoSQL database.',
      :website => 'http://www.mongodb.org/',
      :requires => [],
      :conflicts => [],
      :help_topics => {
      }
    },
    "mysql-5.1" =>
    {
      :name => 'mysql-5.1',
      :display_name => 'MySQL Database 5.1',
      :type => 'embedded',
      :version => 'MySQL 5.1',
      :license => 'GPLv2 with exceptions',
      :license_url => 'http://www.mysql.com/about/legal/licensing/index.html',
      :categories => [:embedded],
      :description => 'MySQL is a multi-user, multi-threaded SQL database server.',
      :website => 'http://www.mysql.com/',
      :requires => [],
      :conflicts => ['postgresql-8.4'],
      :help_topics => {
      }
    },
    "postgresql-8.4" =>
    {
      :name => 'postgresql-8.4',
      :display_name => 'PostgreSQL Database 8.4',
      :type => 'embedded',
      :version => 'PostgreSQL 8.4',
      :license => 'PostgreSQL',
      :license_url => "http://www.postgresql.org/about/licence/",
      :categories => [:embedded],
      :description => 'PostgreSQL is an advanced Object-Relational database management system',
      :website => 'http://www.postgresql.org/',
      :requires => [],
      :conflicts => ['mysql-5.1'],
      :help_topics => {
      }
    },
    "cron-1.4" =>
    {
      :name => 'cron-1.4',
      :display_name => 'Cron 1.4',
      :type => 'embedded',
      :version => 'Cron 1.4',
      :license => 'MIT and BSD and ISC and GPLv2',
      :license_url => nil,
      :categories => [:embedded],
      :description => 'The Cron cartridge allows you to run command line programs at scheduled times. Use this for background jobs and periodic processing.',
      :website => 'https://fedorahosted.org/cronie/',
      :requires => [],
      :conflicts => [],
      :help_topics => {
      }
    },
    "10gen-mms-agent-0.1" =>
    {
      :name => '10gen-mms-agent-0.1',
      :display_name => '10gen - MongoDB Monitoring Service Agent',
      :type => 'embedded',
      :version => '10gen MMS Agent 0.1',
      :license => nil,
      :license_url => nil,
      :categories => [:embedded, :blacklist],
      :description => 'This cartridge provides the agent for connecting to 10gen\'s MongoDB Monitoring Service.  MongoDB Monitoring Service is a publicly available SaaS solution for proactive monitoring of your MongoDB cluster.  You must install the MongoDB cartridge before installing 10gen MMS Agent.',
      :website => 'http://www.10gen.com/mongodb-monitoring-service',
      :requires => [],
      :conflicts => [],
      :help_topics => {
      }
    },
    "phpmyadmin-3.4" =>
    {
      :name => 'phpmyadmin-3.4',
      :display_name => 'phpMyAdmin 3.4',
      :type => 'embedded',
      :version => 'phpMyAdmin 3.4',
      :license => 'GPLv2',
      :license_url => 'http://www.phpmyadmin.net/home_page/license.php',
      :categories => [:embedded],
      :description => 'Web based MySQL admin tool.  Requires the MySQL cartridge to be installed first.',
      :website => 'http://www.phpmyadmin.net/',
      :requires => ['mysql-5.1'],
      :conflicts => [],
      :help_topics => {
      }
    },
    "metrics-0.1" =>
    {
      :name => 'metrics-0.1',
      :display_name => 'OpenShift Metrics 0.1',
      :type => 'embedded',
      :version => 'Metrics 0.1',
      :license => nil,
      :license_url => nil,
      :categories => [:embedded, :experimental],
      :description => 'An experimental cartridge that demonstrates retrieving real-time statistics from your application. May be removed or replaced in the future.',
      :website => nil,
      :requires => [],
      :conflicts => [],
      :help_topics => {
      }
    },
    "phpmoadmin-1.0" =>
    {
      :name => 'phpmoadmin-1.0',
      :display_name => 'phpMoAdmin 1.0',
      :type => 'embedded',
      :version => 'phpMoAdmin 1.0',
      :license => 'GPL v3',
      :license_url => 'http://www.gnu.org/licenses/gpl-3.0.html',
      :categories => [:embedded],
      :description => 'Web based MongoDB administration tool. Requires the MongoDB cartridge to be installed first.',
      :website => 'http://www.phpmoadmin.com/',
      :requires => ['mongodb-2.0'],
      :conflicts => [],
      :help_topics => {
      }
    },
    "rockmongo-1.1" =>
    {
      :name => 'rockmongo-1.1',
      :display_name => 'RockMongo 1.1',
      :type => 'embedded',
      :version => 'RockMongo 1.1',
      :license => 'BSD',
      :license_url => 'http://www.opensource.org/licenses/bsd-license.php',
      :categories => [:embedded],
      :description => 'Web based MongoDB administration tool. Requires the MongoDB cartridge to be installed first.',
      :website => 'http://code.google.com/p/rock-php/wiki/rock_mongo',
      :requires => ['mongodb-2.0'],
      :conflicts => [],
      :help_topics => {
      }
    },
    "jenkins-client-1.4" =>
    {
      :name => 'jenkins-client-1.4',
      :display_name => 'Jenkins Client 1.4',
      :type => 'embedded',
      :version => 'Jenkins Client 1.4',
      :license => 'MIT',
      :license_url => 'http://www.opensource.org/licenses/mit-license.php',
      :categories => [:embedded, :blacklist],
      :description => RDiscount.new("The Jenkins client connects to your Jenkins application and enables builds and testing of your application.\n\nRequires the Jenkins Application to be [created via the new application page](/app/console/application_types)."),
      :website => 'https://jenkins-ci.org/',
      :requires => [],
      :conflicts => [],
      :help_topics => {
      }
    },
    "haproxy-1.4" =>
    {
      :name => 'haproxy-1.4',
      :display_name => 'High Availability Proxy',
      :type => 'embedded',
      :version => '1.4',
      :license => '',
      :license_url => '',
      :categories => [:embedded, :blacklist],
      :description => '',
      :requires => [],
      :conflicts => [],
      :help_topics => {
      }
    }
  }

#  def self.find(*arguments)
#    scope   = arguments.slice!(0)
#    options = arguments.slice!(0) || {}

#    path = "#{prefix}.json"
#    rest_types = format.decode(connection(options).get(path, headers).body)

#    default_types = rest_types.map do |t|
#      CartridgeType.new :display_name => name
#    end

#    case scope
#    when String
#      default_types.find { |type| type.id == scope } or raise NotFound
#    when :all
#      default_types
#when Symbol
#      default_types.find { |type| type.categories.include? scope }
#    else
#  raise "Unsupported scope"
#    end
#  end

  def self.embedded(options={})
    CartridgeType.all options.dup.merge!(:from => :embedded)
  end

  protected
    def self.find_single(scope, options)
      embedded(options).find{ |t| t.to_param == scope } or raise ActiveResource::ResourceNotFound, scope
    end

  private 
    def self.defaults(name)
      @type_map[name] || {}
    end
end
