module AdminConsole
  module Rescue
    extend ActiveSupport::Concern

    included do
      rescue_from Mongoid::Errors::DocumentNotFound, :with => :page_not_found
    end

    protected
      def page_not_found(e=nil, message=nil, alternatives=nil)
        @reference_id = request.uuid
        logger.warn "Page not found - Reference ##{@reference_id}"
        @message, @alternatives = message, alternatives
        render 'not_found'
      end

      def log_error(e, msg="Unhandled exception")
        logger.error "#{msg} reference ##{request.uuid}: #{e.message}\n#{e.backtrace.join("\n  ")}"
      end
  end
end
