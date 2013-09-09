module AdminConsole
  module Rescue
    extend ActiveSupport::Concern

    included do
      rescue_from Mongoid::Errors::DocumentNotFound, :with => :page_not_found
      rescue_from Mongo::ConnectionFailure, :with => :mongo_connection_failure
      rescue_from Moped::Errors::ConnectionFailure, :with => :mongo_connection_failure
    end

    protected
      def page_not_found(e=nil, message=nil, alternatives=nil)
        @reference_id = request.uuid
        logger.warn "Page not found - Reference ##{@reference_id}"
        @message, @alternatives = message, alternatives
        render 'not_found'
      end

      def mongo_connection_failure(e=nil)
        @reference_id = request.uuid
        logger.warn "Mongo connection failure - Reference ##{@reference_id}"
        @message, @alternatives = "Failed to connect to MongoDB", nil
        render 'error'
      end

      def log_error(e, msg="Unhandled exception")
        logger.error "#{msg} reference ##{request.uuid}: #{e.message}\n#{e.backtrace.join("\n  ")}"
      end
  end
end
