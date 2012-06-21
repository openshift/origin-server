class CartridgeType < RestApi::Base
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  include RestApi::Cacheable
  include Comparable

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
  attr_accessor :conflicts, :requires
  attr_accessor :help_topics
  attr_accessor :priority

  self.element_name = 'cartridges'

  def initialize(attributes={},persisted=true)
    name = attributes['name'].presence || attributes[:name].presence
    defaults = self.class.defaults(name)
    attr = attributes.reverse_merge!(defaults)
    super attr, true
  end

  def type
    (@attributes[:type] || :embedded).to_sym
  end

  def embedded?;    type == :embedded; end
  def standalone?;  type == :standalone; end

  def display_name
    @display_name || name
  end

  def categories
    @categories || []
  end
  def categories=(cats)
    @categories = cats.map{ |c| c.to_sym }.compact
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
    c = self.class.category_compare(categories, other.categories)
    return c unless c == 0
    display_name <=> other.display_name
  end

  def to_application_type
    attrs = {:id => name, :name => display_name}
    [:version, :license, :license_url, :categories, :description, :website, :help_topics].each do |m|
      attrs[m] = send(m)
    end
    ApplicationType.new attrs
  end

  def self.embedded(*arguments)
    all(*arguments).select(&:embedded?)
  end
  #cache_method :embedded, [CartridgeType.name, :embedded], :after => lambda { |e| e.each { |c| c.as = nil } }

  def self.standalone(*arguments)
    all(*arguments).select(&:standalone?)
  end

  cache_method :all, [name, :all], :before => lambda { |e| e.each { |c| c.as = nil } }

  def self.category_compare(a,b)
    [:web, :database].each do |t|
      if a.include? t
        return -1 unless b.include? t
      else
        return 1 if b.include? t
      end
    end
    0
  end

  protected
    def self.find_single(scope, options)
      all(options).find{ |t| t.to_param == scope } or new(:name => scope, :as => options[:as])
    end

    #FIXME: Move to YAML and then to server side
    @@types = [
      {
        :name => 'mongodb-2.0',
        :display_name => 'MongoDB NoSQL Database 2.0',
        :type => 'embedded',
        :version => 'MongoDB 2.0',
        :license => 'ASL 2.0 and AGPLv3',
        :license_url => 'http://www.mongodb.org/display/DOCS/Licensing',
        :categories => [:embedded, :database],
        :description => 'MongoDB is a scalable, high-performance, open source NoSQL database.',
        :website => 'http://www.mongodb.org/',
        :requires => [],
        :conflicts => [],
        :help_topics => {
        }
      },
      {
        :name => 'mysql-5.1',
        :display_name => 'MySQL Database 5.1',
        :type => 'embedded',
        :version => 'MySQL 5.1',
        :license => 'GPLv2 with exceptions',
        :license_url => 'http://www.mysql.com/about/legal/licensing/index.html',
        :categories => [:embedded, :database],
        :description => 'MySQL is a multi-user, multi-threaded SQL database server.',
        :website => 'http://www.mysql.com/',
        :requires => [],
        :conflicts => ['postgresql-8.4'],
        :help_topics => {
        }
      },
      {
        :name => 'postgresql-8.4',
        :display_name => 'PostgreSQL Database 8.4',
        :type => 'embedded',
        :version => 'PostgreSQL 8.4',
        :license => 'PostgreSQL',
        :license_url => "http://www.postgresql.org/about/licence/",
        :categories => [:embedded, :database],
        :description => 'PostgreSQL is an advanced Object-Relational database management system',
        :website => 'http://www.postgresql.org/',
        :requires => [],
        :conflicts => ['mysql-5.1'],
        :help_topics => {
        }
      },
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
      {
        :name => '10gen-mms-agent-0.1',
        :display_name => '10gen - MongoDB Monitoring Service Agent',
        :type => 'embedded',
        :version => '10gen MMS Agent 0.1',
        :license => nil,
        :license_url => nil,
        :categories => [:embedded, :blacklist, :administration],
        :description => 'This cartridge provides the agent for connecting to 10gen\'s MongoDB Monitoring Service.  MongoDB Monitoring Service is a publicly available SaaS solution for proactive monitoring of your MongoDB cluster.  You must install the MongoDB cartridge before installing 10gen MMS Agent.',
        :website => 'http://www.10gen.com/mongodb-monitoring-service',
        :requires => [],
        :conflicts => [],
        :help_topics => {
        }
      },
      {
        :name => 'phpmyadmin-3.4',
        :display_name => 'phpMyAdmin 3.4',
        :type => 'embedded',
        :version => 'phpMyAdmin 3.4',
        :license => 'GPLv2',
        :license_url => 'http://www.phpmyadmin.net/home_page/license.php',
        :categories => [:embedded, :administration],
        :description => 'Web based MySQL admin tool.  Requires the MySQL cartridge to be installed first.',
        :website => 'http://www.phpmyadmin.net/',
        :requires => ['mysql-5.1'],
        :conflicts => [],
        :help_topics => {
        }
      },
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
      {
        :name => 'phpmoadmin-1.0',
        :display_name => 'phpMoAdmin 1.0',
        :type => 'embedded',
        :version => 'phpMoAdmin 1.0',
        :license => 'GPL v3',
        :license_url => 'http://www.gnu.org/licenses/gpl-3.0.html',
        :categories => [:embedded, :administration],
        :description => 'Web based MongoDB administration tool. Requires the MongoDB cartridge to be installed first.',
        :website => 'http://www.phpmoadmin.com/',
        :requires => ['mongodb-2.0'],
        :conflicts => [],
        :help_topics => {
        }
      },
      {
        :name => 'rockmongo-1.1',
        :display_name => 'RockMongo 1.1',
        :type => 'embedded',
        :version => 'RockMongo 1.1',
        :license => 'BSD',
        :license_url => 'http://www.opensource.org/licenses/bsd-license.php',
        :categories => [:embedded, :administration],
        :description => 'Web based MongoDB administration tool. Requires the MongoDB cartridge to be installed first.',
        :website => 'http://code.google.com/p/rock-php/wiki/rock_mongo',
        :requires => ['mongodb-2.0'],
        :conflicts => [],
        :help_topics => {
        }
      },
      {
        :name => 'jenkins-client-1.4',
        :display_name => 'Jenkins Client 1.4',
        :type => 'embedded',
        :version => 'Jenkins Client 1.4',
        :license => 'MIT',
        :license_url => 'http://www.opensource.org/licenses/mit-license.php',
        :categories => [:embedded, :productivity, :builds],
        :description => RDiscount.new("The Jenkins client connects to your Jenkins application and enables builds and testing of your application. Requires the Jenkins Application to be [created via the new application page](/app/console/application_types).").html_safe,
        :website => 'https://jenkins-ci.org/',
        :requires => [],
        :conflicts => [],
        :help_topics => {
        }
      },
      {
        :name => 'haproxy-1.4',
        :display_name => 'High Availability Proxy',
        :type => 'embedded',
        :version => '1.4',
        :license => '',
        :license_url => '',
        :categories => [:blacklist, :scales],
        :description => '',
        :requires => [],
        :conflicts => [],
        :help_topics => {
        }
      },
      {
        :name => 'jbosseap-6.0',
        :type => 'standalone',
        :display_name => 'JBoss Enterprise Application Platform 6.0',
        :version => 'JBoss EAP 6.0.0',
        :license => 'ASL 2.0',
        :license_url => 'http://www.apache.org/licenses/LICENSE-2.0',
        :categories => [:web, :framework, :new],
        :description => 'Market-leading open source enterprise platform for next-generation, highly transactional enterprise Java applications.  Build and deploy enterprise Java in the cloud.',
        :website => 'http://www.redhat.com/products/jbossenterprisemiddleware/application-platform/',
        :help_topics => {
          'How to add JBoss modules to an OpenShift app' => '/community/kb/kb-e1018-how-can-i-add-jboss-modules-to-an-express-app',
          'How to solve java.net.BindException to 8080' => '/community/kb/kb-e1019-my-jboss-application-has-a-bunch-of-javanetbindexceptions-to-8080-when-starting'
        }
      },
      {
        :name => 'jbossas-7',
        :type => 'standalone',
        :display_name => 'JBoss Application Server 7.1',
        :version => 'JBoss AS 7.1.0.Final',
        :license => 'GNU LPGL 2.1',
        :license_url => 'http://www.gnu.org/licenses/lgpl-2.1-standalone.html',
        :categories => [:web, :framework],
        :description => 'The leading open source Java EE6 application server for enterprise Java applications.  Popular development frameworks include Seam, CDI, Weld, and Spring.',
        :website => 'http://www.jboss.org/jbossas',
        :help_topics => {
          'How to add JBoss modules to an OpenShift app' => '/community/kb/kb-e1018-how-can-i-add-jboss-modules-to-an-express-app',
          'How to solve java.net.BindException to 8080' => '/community/kb/kb-e1019-my-jboss-application-has-a-bunch-of-javanetbindexceptions-to-8080-when-starting'
        }
      },
      {
        :name => 'php-5.3',
        :type => 'standalone',
        :display_name => 'PHP 5.3',
        :version => '5.3.2',
        :categories => [:web, :framework],
        :description => 'PHP is a general-purpose server-side scripting language originally designed for Web development to produce dynamic Web pages.  Popular development frameworks include: CakePHP, Zend, Symfony, and Code Igniter.',
        :website => 'http://www.php.net',
  #      :provides => [
  #        'Apache configured with mod_php',
  #        'PHP script directory for you to check PHP files',
  #        'A Git repository you can checkout locally'
  #      ]
      },
      {
        :name => 'python-2.6',
        :type => 'standalone',
        :display_name => 'Python 2.6',
        :version => 'Python 2.6.6 / WSGI 3.2',
        :categories => [:web, :framework],
        :description => 'Python is a general-purpose, high-level programming language whose design philosophy emphasizes code readability. Popular development frameworks include: Django, Bottle, Pylons, Zope and TurboGears.',
        :website => 'http://www.wsgi.org/',
        :help_topics => {
          'Getting Django up and running in 5 minutes' => '/community/kb/kb-e1010-show-me-your-django-getting-django-up-and-running-in-5-minutes'
        }
      },
      {
        :name => 'perl-5.10',
        :type => 'standalone',
        :display_name => 'Perl 5.10',
        :version => 'Perl 5.10 / mod_perl 2.0.4',
        :categories => [:web, :framework],
        :description => 'Perl is a high-level, general-purpose, interpreted, dynamic programming language. Dynamic content produced by Perl scripts can be served in response to incoming web requests.',
        :website => 'http://perl.apache.org/start/index.html',
        :help_topics => {
          'How to onboard a Perl application' => '/community/kb/kb-e1013-how-to-onboard-a-perl-application',
          'How to deploy the Perl Dancer framework' => '/community/kb/kb-e1014-how-to-deploy-the-perl-dancer-framework-on-openshift-express'
        }
      },
      {
        :name => 'nodejs-0.6',
        :type => 'standalone',
        :display_name => 'Node.js 0.6',
        :version => 'Node.js 0.6.10',
        :categories => [:web, :framework],
        :description => 'Node.js is a platform built on Chrome\'s JavaScript runtime for easily building fast, scalable network applications. Node.js is perfect for data-intensive real-time applications that run across distributed devices.',
        :website => 'http://nodejs.org/'
      },
      {
        :name => 'ruby-1.8',
        :type => 'standalone',
        :display_name => 'Ruby 1.8.7',
        :version => 'Ruby 1.8.7 / Rack 1.1',
        :categories => [:web, :framework],
        :description => 'Ruby is a dynamic, reflective, general-purpose object-oriented programming language. Popular development frameworks include Ruby on Rails and Sinatra.',
        :website => 'http://rack.rubyforge.org/'
      },
      {
        :name => 'diy-0.1',
        :type => 'standalone',
        :display_name => 'Do-It-Yourself',
  #      :version => '1.0',
        :categories => [:web, :framework, :custom],
        :description => RDiscount.new('The Do-It-Yourself (DIY) application type is a blank slate for trying unsupported languages, frameworks, and middleware on OpenShift. See [the community site](/community/developers/do-it-yourself) for examples of bringing your favorite framework to OpenShift.').html_safe
        #:website => 'http://perl.apache.org/start/index.html'
      },
      {
        :name => 'jenkins-1.4',
        :display_name => "Jenkins Server",
        :description => RDiscount.new('Jenkins is a continuous integration (CI) build server that is deeply integrated into OpenShift.  See [the Jenkins info page for more](/community/jenkins).').html_safe,
        :version => '1.4',
        :categories => [:framework, :productivity, :web],
      },
    ].freeze

    @@type_map = @@types.inject({}) { |i, t| i[t[:name]] = t; t.freeze; i }.freeze

    def self.known_types
      @@types
    end
    def self.type_map
      @@type_map
    end
    def self.defaults(name)
      attrs = type_map[name.to_s]
      Rails.logger.warn "> The cartridge type '#{name}' is not defined - no metadata is available." unless attrs
      attrs || {}
    end

end
