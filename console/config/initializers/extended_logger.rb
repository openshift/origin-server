if Rails.version[0..3] != '3.0.'
  class ActiveSupport::BufferedLogger
    def formatter=(formatter)
      @log.formatter = formatter
    end
  end

  class Formatter
    SEVERITY_TO_TAG_MAP     = {'DEBUG'=>'meh', 'INFO'=>'fyi', 'WARN'=>'hmm', 'ERROR'=>'wtf', 'FATAL'=>'omg', 'UNKNOWN'=>'???'}
    SEVERITY_TO_COLOR_MAP   = {'DEBUG'=>'0;37', 'INFO'=>'32', 'WARN'=>'33', 'ERROR'=>'31', 'FATAL'=>'31', 'UNKNOWN'=>'37'}
    USE_HUMOROUS_SEVERITIES = true

    attr_accessor :omit_pid

    def call(severity, time, progname, msg)
      formatted_severity = sprintf("%-5s","#{severity}")

      formatted_time = time.strftime("%Y-%m-%d %H:%M:%S.") << time.usec.to_s[0..2].rjust(3)
      color = SEVERITY_TO_COLOR_MAP[severity]

      _msg = "\033[0;37m#{formatted_time}\033[0m [\033[#{color}m#{formatted_severity}\033[0m] #{msg.strip}"
      _msg << "(pid:#{$$})" unless omit_pid
      return "#{_msg}\n"
    end
  end

  Rails.logger.formatter = Formatter.new

else

  require 'active_support/buffered_logger'

  #
  # Rails <3.2 does not support a formatter option, so we override BufferedLogger
  # See http://cbpowell.wordpress.com/2012/04/05/beautiful-logging-for-ruby-on-rails-3-2/
  # for more info about upgrading in Rails 3.2
  #
  raise "Code needs upgrade for rails 3.2+" if Rails.version[0..3] != '3.0.'

  class ActiveSupport::BufferedLogger
    SEVERITIES = Severity.constants.sort_by{|c| Severity.const_get(c) }

    def add(severity, message = nil, progname = nil, &block)
      return if @level > severity
      message = (message || (block && block.call) || progname).to_s
      # Prepend pid and severity to the written message
      log = "[%s] %-5.5s %s" % [$$, SEVERITIES[severity], message.gsub(/^\n+/, '')]
      # If a newline is necessary then create a new message ending with a newline.
      log << "\n" unless log[-1] == ?\n
      buffer << log
      auto_flush
      message
    end
  end
end
