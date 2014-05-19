module OpenShift
  module Controller
    module ApiResponses
      extend ActiveSupport::Concern

      included do
        respond_to :json, :xml
        self.responder = OpenShift::Responder

        rescue_from ::Exception, :with => :render_exception
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
            log_action(action_log_tag, status, !internal_error, msg, get_log_args, messages.map(&:text).join(', '))
          else
            msg_type = :error unless msg_type
            reply.messages.push(Message.new(msg_type, msg, err_code, field)) if msg
            log_action(action_log_tag, status, !internal_error, msg, get_log_args)
          end
          if @analytics_tracker
            event_name = nil
            if internal_error
              event_name = 'render_error'
            else
              event_name = 'render_user_error'
            end
            @analytics_tracker.track_event(event_name, @domain, @application, {'request_path' => request.fullpath, 'request_method' => request.method, 'status_code' => status, 'error_code' => err_code, 'error_field' => field})
          end
          respond_with reply, :status => reply.status
        end

        # Renders a REST response for an application being upgraded.
        def render_upgrade_in_progress
          return render_error(:unprocessable_entity, "Your application is being upgraded and configuration changes can not be made at this time.  Please try again later.", 1)
        end

        # Renders a REST response for an exception.
        #
        # == Parameters:
        #  ex::
        #    The exception to return to the user.

        def render_exception(ex)
          error_code = ex.respond_to?(:code) ? ex.code : 1
          message = ex.message
          internal_error = true
          field = ex.respond_to?(:field) ? ex.field : nil

          case ex
          when OpenShift::ValidationException
            return render_error(:unprocessable_entity, nil, nil, nil, nil, get_error_messages(ex.resource))

          when Mongoid::Errors::Validations
            field_map =
              case ex.document
              when Domain then requested_api_version <= 1.5 ? {"namespace" => "id"} : {"namespace" => "name"}
              end
            messages = get_error_messages(ex.document, field_map || {})
            return render_error(:unprocessable_entity, nil, nil, nil, nil, messages)

          when Mongoid::Errors::InvalidFind
            status = :not_found
            message = "No resource was requested."
            internal_error = false

          when Mongoid::Errors::DocumentNotFound
            status = :not_found
            model = ex.klass

            target =
              if    ComponentInstance >= model then target = 'Cartridge'
              elsif CartridgeInstance >= model then target = 'Cartridge'
              elsif CartridgeType     >= model then target = 'Cartridge'
              elsif GroupInstance     >= model then target = 'Gear group'
              else  model.to_s.underscore.humanize
              end

            message =
              if ex.unmatched.length > 1
                "The #{target.pluralize.downcase} with ids #{ex.unmatched.map{ |id| "'#{id}'"}.join(', ')} were not found."
              elsif ex.unmatched.length == 1
                "#{target} '#{ex.unmatched.first}' not found."
              else
                if name = (
                  (Domain >= model and ex.params[:canonical_namespace].presence) or
                  (Application >= model and ex.params[:canonical_name].presence) or
                  (ComponentInstance >= model and ex.params[:cartridge_name].presence) or
                  (CartridgeInstance >= model and ex.params[:name].presence) or
                  (CartridgeType     >= model and ex.params[:name].presence) or
                  (Alias >= model and ex.params[:fqdn].presence) or
                  (CloudUser >= model and ex.params[:login].presence) or
                  (CloudUser >= model and ex.params[:_id].presence) or
                  (SshKey >= model and ex.params[:name].presence)
                )
                  "#{target} '#{name}' not found."
                else
                  "The requested #{target.downcase} was not found."
                end
              end
            error_code =
              if    Cartridge         >= model then 129
              elsif ComponentInstance >= model then 129
              elsif SshKey            >= model then 118
              elsif GroupInstance     >= model then 101
              elsif Authorization     >= model then 129
              elsif Domain            >= model then 127
              elsif Alias             >= model then 173
              elsif Application       >= model then 101
              else  error_code
              end
            internal_error = false

          when OpenShift::UserException
            status = ex.response_code || :unprocessable_entity
            error_code, node_message, messages = extract_node_messages(ex, error_code, message, field)
            message = node_message || "Unable to complete the requested operation. \nReference ID: #{request.uuid}"
            messages.push(Message.new(:error, message, error_code, field))
            return render_error(status, message, error_code, field, nil, messages, false)

          when OpenShift::AccessDeniedException
            status = :forbidden
            internal_error = false

          when OpenShift::AuthServiceException
            status = :internal_server_error
            message = "Unable to authenticate the user. Please try again and contact support if the issue persists. \nReference ID: #{request.uuid}"

          when OpenShift::DNSException, OpenShift::DNSLoginException
            status = :internal_server_error

          when OpenShift::LockUnavailableException
            status = :internal_server_error
            message ||= "Another operation is already in progress. Please try again in a minute."
            internal_error = false

          when OpenShift::NodeUnavailableException
            Rails.logger.error "Got Node Unavailable Exception"
            status = :internal_server_error
            message = ""
            if ex.resultIO
              error_code = ex.resultIO.exitcode
              message = ex.resultIO.errorIO.string.strip + "\n" unless ex.resultIO.errorIO.string.empty?
              Rail.logger.error "message: #{message}"
            end
            message ||= ""
            message += "Unable to complete the requested operation due to: #{ex.message}. Please try again and contact support if the issue persists. \nReference ID: #{request.uuid}"

          when OpenShift::ApplicationOperationFailed
            status = :internal_server_error
            error_code, node_message, messages = extract_node_messages(ex, error_code, message, field)
            messages.push(Message.new(:error, node_message, error_code, field)) unless node_message.blank?
            message = "#{message}\nReference ID: #{request.uuid}"
            return render_error(status, message, error_code, field, nil, messages, internal_error)

          when OpenShift::NodeException, OpenShift::OOException
            status = :internal_server_error
            error_code, message, messages = extract_node_messages(ex, error_code, message, field)
            message ||= "unknown error"
            message = "Unable to complete the requested operation due to: #{message}\nReference ID: #{request.uuid}"

            # just trying to make sure that the error message is the last one to be added
            messages.push(Message.new(:error, message, error_code, field))

            return render_error(status, message, error_code, field, nil, messages, internal_error)
          else
            status = :internal_server_error
            message = "Unable to complete the requested operation due to: #{message}\nReference ID: #{request.uuid}"
          end

          Rails.logger.error "Reference ID: #{request.uuid} - #{ex.message}\n  #{ex.backtrace.join("\n  ")}" if internal_error

          render_error(status, message, error_code, field, nil, nil, internal_error)
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

          reply.messages.each do |message|
            message.field = :result if message.severity == :result
          end if requested_api_version <= 1.5

          log_args = get_log_args.merge(extra_log_args)

          if extra_messages.present?
            extra_messages = Array(extra_messages)
            reply.messages.concat(extra_messages)
            log_action(action_log_tag, status, true, message, log_args, extra_messages.map(&:text).join(', '))
          else
            log_action(action_log_tag, status, true, message, log_args)
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
        def get_error_messages(object, field_name_map={}, for_index=false)
          messages = []
          Array(object).each_with_index do |o, i|
            o.errors.keys.each do |key|
              field = field_name_map[key.to_s] || key.to_s
              err_msgs = o.errors.get(key)
              err_msgs.each do |err_msg|
                messages.push(Message.new(:error, err_msg, o.class.validation_map[key], field, (i if for_index)))
              end if err_msgs
            end if o.respond_to?(:errors) && o.errors.respond_to?(:keys)
          end
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
          args["APP_UUID"] = @application.uuid if @application
          args["DOMAIN"] = (@application.domain_namespace if @application) || (@domain.namespace if @domain)
          args
        end

        protected
          def extract_node_messages(ex, code=nil, message=nil, field=nil)
            messages = []
            if ex.respond_to?(:resultIO) && ex.resultIO
              code = ex.resultIO.exitcode
              message = ex.resultIO.errorIO.string.strip + "\n" unless ex.resultIO.errorIO.string.empty?

              messages.push(Message.new(:debug, ex.resultIO.debugIO.string, code, field)) unless ex.resultIO.debugIO.string.empty?
              messages.push(Message.new(:warning, ex.resultIO.messageIO.string, code, field)) unless ex.resultIO.messageIO.string.empty?
              messages.push(Message.new(:result, ex.resultIO.resultIO.string, code, field)) unless ex.resultIO.resultIO.string.empty?
            end
            [code, message, messages]
          end
    end
  end
end
