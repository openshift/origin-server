class ActiveSupport::BufferedLogger
  def formatter=(formatter)
    @log.formatter = formatter
  end
end

module OpenShift
  class Formatter
    if Rails.env.development? or ENV['COLOR_LOGS']
      SEVERITY_TO_COLOR_MAP   = {'DEBUG'=>'0;37', 'INFO'=>'32', 'WARN'=>'33', 'ERROR'=>'31', 'FATAL'=>'31', 'UNKNOWN'=>'37'}
  
      def call(severity, time, progname, msg)
        formatted_severity = sprintf("%-5s","#{severity}")
  
        formatted_time = time.strftime("%Y-%m-%d %H:%M:%S.") << time.usec.to_s[0..2].rjust(3)
        color = SEVERITY_TO_COLOR_MAP[severity]
  
        "\033[0;37m#{formatted_time}\033[0m [\033[#{color}m#{formatted_severity}\033[0m] #{msg.strip} (pid:#{$$})\n"
      end
  
    else
  
      def call(severity, time, progname, msg)
        formatted_severity = sprintf("%-5s","#{severity}")
  
        formatted_time = time.strftime("%Y-%m-%d %H:%M:%S.") << time.usec.to_s[0..2].rjust(3)
  
        "#{formatted_time} [#{formatted_severity}] #{msg.strip} (pid:#{$$})\n"
      end
  
    end
  end
end

Rails.logger.formatter = OpenShift::Formatter.new

if Rails.env.development? and not ENV['ASSET_LOGS']
  Rails::Rack::Logger.class_eval do 
    def call_with_quiet_assets(env)
      previous_level = Rails.logger.level
      Rails.logger.level = Logger::ERROR if env['PATH_INFO'].index("/assets/") == 0 
      call_without_quiet_assets(env).tap do
        Rails.logger.level = previous_level
      end 
    end 
    alias_method_chain :call, :quiet_assets 
  end 
end