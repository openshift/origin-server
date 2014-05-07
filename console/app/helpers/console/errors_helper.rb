module Console::ErrorsHelper

  def flash_messages(messages, default=nil)
    if messages.present?
      flashes = {}
      messages.each do |message|
        text = (message[:text] || message.text).byteslice(0, 2 * 1024)
        if !defined?(message.severity) || !message.severity || message.severity == 'info'
          flashes[:success] = text
        else
          flashes[message.severity.to_sym] = text
        end
      end
      flashes
    else
      default
    end
  end

end