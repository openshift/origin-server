module OpenShift
  module Utils
    class Sdk
      MARKER = 'CARTRIDGE_VERSION_2'
      V1_CARTRIDGES = %w(10gen-mms-agent-0.1  
           cron-1.4 diy-0.1 haproxy-1.4  
           jbossas-7 jbosseap-6.0 jbossews-1.0 jbossews-2.0 
           jenkins-1.4 jenkins-client-1.4 mongodb-2.2 mysql-5.1 
           mongodb-2.2 nodejs-0.6 perl-5.10 php-5.3 postgresql-8.4 python-2.6
           phpmyadmin-3.4 
           ruby-1.8 ruby-1.9 switchyard-0.6
           metrics-0.1 rockmongo-1.1 zend-5.6)
           # todo, figure out how to load extensions to this list if 
           # we keep this mechanism around - last 3 carts are from
           # internal repo

      def self.is_new_sdk_app(gear_home)
        File.exists?(File.join(gear_home, '.env', MARKER))
      end

      def self.mark_new_sdk_app(gear_home) 
        FileUtils.touch(File.join(gear_home, '.env', MARKER))
      end

      def self.v1_cartridges
        V1_CARTRIDGES
      end
    end
  end
end