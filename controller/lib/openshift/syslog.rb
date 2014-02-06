module OpenShift
  class Syslog
    def self.logger_for(program_name, message_source)
      require 'syslog-logger'
      Logger::Syslog.new(program_name).tap do |logger|
        logger.formatter = proc do |severity, datetime, progname, msg|
          "#{severity} src=#{message_source} #{msg.strip}\n"
        end
      end
    end
  end
end
