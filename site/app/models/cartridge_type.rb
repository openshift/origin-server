class CartridgeType < RestApi::Base
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  class NotFound < StandardError
  end

  schema do
    string :name, :type
  end

  attr_accessor :name, :id, :version, :description
  attr_accessor :provides
  attr_accessor :cartridge
  attr_accessor :website, :license, :license_url
  attr_accessor :categories, :learn_more_url
  attr_accessor :help_topics

  self.prefix = "#{RestApi::Base.site.path}/cartridges/embedded"

  def type
    @attributes[:type]
  end

  def type=(type)
    @attributes[:type]=type
  end

  def initialize(attributes={})
    @attributes={}
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
      :requires => [],
      :conflicts => [],
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
      :requires => [],
      :conflicts => ['postgresql-8.4'],
      :help_topics => {
      }
    },
    "cron-1.4" =>
    {
      :id => 'cron-1.4',
      :name => 'Cron 1.4',
      :type => 'embedded',
      :version => 'Cron 1.4',
      :license => 'MIT and BSD and ISC and GPLv2',
      :license_url => nil,
      :categories => [:embedded],
      :description => 'Cron is a daemon that runs specified programs at scheduled times',
      :website => 'https://fedorahosted.org/cronie/',
      :requires => [],
      :conflicts => [],
      :help_topics => {
      }
    },
    "postgresql-8.4" =>
    {
      :id => 'postgresql-8.4',
      :name => 'PostgreSQL Database 8.4',
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
    "10gen-mms-agent-0.1" =>
    {
      :id => '10gen-mms-agent-0.1',
      :name => '10gen - MongoDB Monitoring Service Agent',
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
      :id => 'phpmyadmin-3.4',
      :name => 'phpMyAdmin 3.4',
      :type => 'embedded',
      :version => 'phpMyAdmin 3.4',
      :license => 'GPLv2',
      :license_url => 'http://www.phpmyadmin.net/home_page/license.php',
      :categories => [:embedded],
      :description => 'Web based MySQL admin tool.  Requires the MySQL cartridge to be installed first.',
      :website => 'https://fedorahosted.org/cronie/',
      :requires => ['mysql-5.1'],
      :conflicts => [],
      :help_topics => {
      }
    },
    "metrics-0.1" =>
    {
      :id => 'metrics-0.1',
      :name => 'OpenShift Metrics 0.1',
      :type => 'embedded',
      :version => 'Metrics 0.1',
      :license => nil,
      :license_url => nil,
      :categories => [:embedded, :blacklist],
      :description => 'The OpenShift Metrics cartridge',
      :website => nil,
      :requires => [],
      :conflicts => [],
      :help_topics => {
      }
    },
    "phpmoadmin-1.0" =>
    {
      :id => 'phpmoadmin-1.0',
      :name => 'phpMoAdmin 1.0',
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
      :id => 'rockmongo-1.1',
      :name => 'RockMongo 1.1',
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
      :id => 'jenkins-client-1.4',
      :name => 'Jenkins Client 1.4',
      :type => 'embedded',
      :version => 'Jenkins Client 1.4',
      :license => 'MIT',
      :license_url => 'http://www.opensource.org/licenses/mit-license.php',
      :categories => [:embedded, :blacklist],
      :description => 'Tool for running and monitoring jobs such as continuous building and testing of your OpenShift applications.  Requires the Jenkins Server Application to be created first.',
      :website => 'https://jenkins-ci.org/',
      :requires => [],
      :conflicts => [],
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
          CartridgeType.new({:id => name, :name => name, :type => t['type'], :categories => [t['type']]})
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
