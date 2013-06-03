module OpenShift
  module Controller
    module ApiResponses
      extend ActiveSupport::Concern

      included do
        respond_to :json, :xml
        self.responder = OpenShift::Responder
      end

      protected

        # Renders a REST response for an unsuccessful request.
        #
        # == Parameters:
        #  status::
        #    HTTP Success code. See {ActionController::StatusCodes::SYMBOL_TO_STATUS_CODE}
        #  msg::
        #    The error message returned in the REST response
        #  err_code::
        #    Error code for the message in the REST response
        #  field::
        #    Specified the field (if any) that the message applies to.
        #  msg_type::
        #    Can be one of :error, :warning, :info. Defaults to :error
        #  messages::
        #    Array of message objects. If provided, it will log all messages in the action log and will add them to the REST response.
        #    msg,  err_code, field, and msg_type will be ignored.
        def render_error(status, msg, err_code=nil, field=nil, msg_type=nil, messages=nil, internal_error=false)
          reply = new_rest_reply(status)
          if messages.present?
            reply.messages.concat(messages)
            log_action(@log_tag, !internal_error, msg, get_log_args, messages.map(&:text).join(', '))
          else
            msg_type = :error unless msg_type
            reply.messages.push(Message.new(msg_type, msg, err_code, field)) if msg
            log_action(@log_tag, !internal_error, msg, get_log_args)
          end
          respond_with reply
        end

        # Renders a REST response for an exception.
        #
        # == Parameters:
        #  ex::
        #    The exception to return to the user.

        def render_exception(ex)
          Rails.logger.error "Reference ID: #{request.uuid} - #{ex.message}\n  #{ex.backtrace.join("\n  ")}"
          error_code = ex.respond_to?('code') ? ex.code : 1
          message = ex.message
          if ex.kind_of? OpenShift::UserException
            status = :unprocessable_entity
          elsif ex.kind_of? OpenShift::AccessDeniedException
            status = :forbidden
          elsif ex.kind_of? OpenShift::DNSException
            status = :service_unavailable
          elsif ex.kind_of? OpenShift::NodeException
            status = :internal_server_error
            if ex.resultIO
              error_code = ex.resultIO.exitcode
              message = ""
              if ex.resultIO.errorIO && ex.resultIO.errorIO.length > 0
                message = ex.resultIO.errorIO.string.strip
              end
              message ||= ""
              message += "Unable to complete the requested operation due to: #{ex.message}.\nReference ID: #{request.uuid}"
            end
          else
            status = :internal_server_error
            message = "Unable to complete the requested operation due to: #{ex.message}.\nReference ID: #{request.uuid}"
          end

          internal_error = status != :unprocessable_entity
          render_error(status, message, error_code, nil, nil, nil, internal_error)
        end

        # Renders a REST response with for a successful request.
        #
        # == Parameters:
        #  status::
        #    HTTP Success code. See {ActionController::StatusCodes::SYMBOL_TO_STATUS_CODE}
        #  type::
        #    Rest object type.
        #  data::
        #    REST Object to render
        #  message::
        #    Message to be returned to REST response and logged
        #  extra_messages::
        #    Array of message objects. If provided, it will log all messages in the action log and will add them to the REST response.

        def render_success(status, type, data, message=nil, result=nil ,extra_messages=nil, extra_log_args={})
          reply = new_rest_reply(status, type, data)
          reply.messages.push(Message.new(:info, message)) if message
          reply.process_result_io(result) if result
          
          log_args = get_log_args.merge(extra_log_args)
          
          if extra_messages.present?
            reply.messages.concat(messages)
            log_action(@log_tag, true, message, log_args, messages.map(&:text).join(', '))
          else
            log_action(@log_tag, true, message, log_args)
          end
          respond_with reply
        end

        # Process all validation errors on a model and returns an array of message objects.
        #
        # == Parameters:
        #  object::
        #    MongoId model to process
        #  field_name_map::
        #    Maps an internal field name to a user visible field name. (Optional)
        def get_error_messages(object, field_name_map={})
          messages = []
          object.errors.keys.each do |key|
            field = field_name_map[key.to_s] || key.to_s
            err_msgs = object.errors.get(key)
            err_msgs.each do |err_msg|
              messages.push(Message.new(:error, err_msg, object.class.validation_map[key], field))
            end if err_msgs
          end if object && object.errors && object.errors.keys
          messages
        end
        
        def new_rest_reply(*arguments)
          RestReply.new(requested_api_version, *arguments)
        end

        #
        # Should be gradually phased out in preference to
        # direct argument passing
        #
        def get_log_args
          args = {}
          args["APP"] = @application_name if @application_name
          args["DOMAIN"] = @domain_name if @domain_name
          args["APP_UUID"] = @application_uuid if @application_uuid
          return args
        end
    end
  end
end
