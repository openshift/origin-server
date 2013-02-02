module OpenShift
  module Controller
    module ApiBehavior
      extend ActiveSupport::Concern

      API_VERSION = 1.3
      SUPPORTED_API_VERSIONS = [1.0, 1.1, 1.2, 1.3]

      protected

        def set_locale
          I18n.locale = nil
        end

        def check_version
          accept_header = request.headers['Accept']
          Rails.logger.debug accept_header    
          mime_types = accept_header ? accept_header.split(%r{,\s*}) : []
          version_header = API_VERSION
          mime_types.each do |mime_type|
            values = mime_type.split(%r{;\s*})
            values.each do |value|
              value = value.downcase
              if value.include?("version")
                version_header = value.split("=")[1].delete(' ').to_f
              end
            end
          end

          #$requested_api_version = request.headers['X_API_VERSION'] 
          if not version_header
            $requested_api_version = API_VERSION
          else
            $requested_api_version = version_header
          end

          if not SUPPORTED_API_VERSIONS.include? $requested_api_version
            invalid_version = $requested_api_version
            $requested_api_version = API_VERSION
            return render_error(:not_acceptable, "Requested API version #{invalid_version} is not supported. Supported versions are #{SUPPORTED_API_VERSIONS.map{|v| v.to_s}.join(",")}")
          end
        end

        def get_url
          @rest_url ||= "#{rest_url}/"
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

