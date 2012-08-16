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

