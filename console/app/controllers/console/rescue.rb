module Console
  module Rescue
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveResource::ConnectionError, :with => :generic_error
      rescue_from ActiveResource::ResourceNotFound, :with => :page_not_found
      rescue_from ActiveResource::ServerError, :with => :server_error
      rescue_from RestApi::ResourceNotFound, :with => :resource_not_found
      rescue_from Console::AccessDenied, :with => :console_access_denied
    end

    protected
      def resource_not_found(e)
        logger.debug "Resource not found: #{e}"
        if respond_to? :domain_is_missing
          domain_is_missing if e.respond_to?(:domain_missing?) && e.domain_missing?
        end

        alternatives = begin
            if Application == e.model
              @domain.applications.map do |app|
                ["Application #{app.name}", application_path(app)]
              end.tap do |links|
                links << ['Create a new application', new_application_path] if links.empty?
              end if @domain rescue nil
            elsif ApplicationType == e.model
              [['See other application types', application_types_path]]
            end
          end if e.respond_to? :model

        page_not_found(e, e.message, alternatives)
      end

      def page_not_found(e=nil, message=nil, alternatives=nil)
        @reference_id = request.uuid
        logger.warn "Page not found - Reference ##{@reference_id}"
        @message, @alternatives = message, alternatives
        render 'console/not_found'
      end

      def generic_error(e=nil, message=nil, alternatives=nil)
        log_error(e) if e
        @reference_id = request.uuid
        @message, @alternatives = message, alternatives
        render 'console/error'
      end

      def console_access_denied(e)
        logger.debug "Access denied: #{e}"
        redirect_to unauthorized_path
      end

      def server_error(e=nil, message=nil, alternatives=nil)
        if e.present? && e.response.present?
          if e.response.code.present? && e.response.code.to_i == 503
            logger.debug "Maintenance in progress: #{e}"
            redirect_to server_unavailable_path
          else
            if (server_messages = RestApi::Base.messages_for e.response).present?
              e = RestApi::ServerError.new(e.response, server_messages.map(&:text).join(' -- '))
              e.set_backtrace($!.backtrace)

              warnings, errors = Array(server_messages).inject([[],[]]) do |a, m|
                text = m.text
                text = (text || "").gsub(/\A\n+/m, "").rstrip
                case m.severity
                when 'warning'
                  a[0] << text
                when 'error'
                  a[1] << text
                end
                a
              end

              flash.now[:warning] = warnings.compact.join(' -- ') unless warnings.empty?
              message = errors.compact.join(' -- ') unless errors.empty?
            end
            logger.debug "Server error: #{e}"            
            generic_error(e, message, alternatives)            
          end
        else
          logger.debug "Server error: #{e}"
          generic_error(e, message, alternatives)
        end
      end

      def log_error(e, msg="Unhandled exception")
        @details = "#{msg} reference ##{request.uuid}: #{e.message}"
        logger.error "#{@details}\n#{e.backtrace.join("\n  ")}"
      end
  end
end
