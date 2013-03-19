module OpenShift
  module Controller
    module ApiBehavior
      extend ActiveSupport::Concern

      API_VERSION = 1.4
      SUPPORTED_API_VERSIONS = [1.0, 1.1, 1.2, 1.3, 1.4]

      protected
        attr :requested_api_version

        def new_rest_reply(*arguments)
          RestReply.new(requested_api_version, *arguments)
        end

        def check_version

          version = catch(:version) do
            (request.accept || "").split(',').each do |mime_type|
              values = mime_type.split(';').map(&:strip)
              @nolinks = true if values.include? 'nolinks'
              values.map(&:strip).map(&:downcase).each do |value|
                throw :version, value.split("=")[1].to_f if value.starts_with? "version"
              end
            end
            nil
          end.presence 
          if version.nil?
            version = API_VERSION
            #FIXME  this is a hack that should be removed by April
            version = 1.3 if request.headers['User-Agent'].present? and request.headers['User-Agent'].start_with? "rhc"
          end
          if SUPPORTED_API_VERSIONS.include? version
            @requested_api_version = version
          else
            @requested_api_version = API_VERSION
            render_error(:not_acceptable, "Requested API version #{version} is not supported. Supported versions are #{SUPPORTED_API_VERSIONS.map{|v| v.to_s}.join(",")}")
          end
        end

        def check_outage
          if Rails.configuration.maintenance[:enabled]
            message = Rails.cache.fetch("outage_msg", :expires_in => 5.minutes) do
              File.read(Rails.configuration.maintenance[:outage_msg_filepath]) rescue nil
            end
            reply = new_rest_reply(:service_unavailable)
            reply.messages.push(Message.new(:info, message)) if message
            respond_with reply
          end
        end

        def get_url
          @rest_url ||= "#{rest_url}/"
        end

        def set_locale
          I18n.locale = nil
        end

        def nolinks
          @nolinks ||= get_bool(params[:nolinks])
        end

        def check_nolinks
          nolinks
        rescue => e
          render_exception(e)
        end
          
        def get_bool(param_value)
          return false unless param_value
          if param_value.is_a? TrueClass or param_value.is_a? FalseClass
            return param_value
          elsif param_value.is_a? String and param_value.upcase == "TRUE"
            return true
          elsif param_value.is_a? String and param_value.upcase == "FALSE"
            return false
          end
          raise OpenShift::OOException.new("Invalid value '#{param_value}'. Valid options: [true, false]", 167)
        end
    end
  end
end

