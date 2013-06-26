module OpenShift
  module Controller
    module ApiBehavior
      extend ActiveSupport::Concern

      API_VERSION = 1.6
      SUPPORTED_API_VERSIONS = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6]

      protected
        attr :requested_api_version

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
        
        def get_log_tag_prepend
          tag = "UNKNOWN"
          case request.method
          when "GET"
            if params[:id]
              tag = "SHOW_"
            else
              tag = "LIST_"
            end
          when "POST"
            tag = "ADD_" 
          when "PUT"
            tag = "UPDATE_"
          when "DELETE"
            tag = "DELETE_"
          end
          return tag
        end 
        
        def get_domain(domain_id=nil)
          #get domain_id from url if domain_id is nil
          domain_id = params[:domain_id] if domain_id.nil?
          domain_id = domain_id.downcase if domain_id
          @domain = Domain.find_by(owner: @cloud_user, canonical_namespace: Domain.check_name!(domain_id))
          @domain
        end

        def get_application
          domain_id = params[:domain_id].presence
          application_id = params[:application_id] || params[:id]
          application_id = application_id.downcase if application_id
          application_name = params[:application_name] || params[:name]
          application_name = application_name.downcase if application_name
          return render_error(:not_found, "Application ID cannot be null", 101) if application_id.nil?

          # if domain_id is nil then assume that retrieving application by ID
          if domain_id.nil?
            @application = Application.find_by(uuid: application_id) rescue nil 
            @domain = @application.domain if @application
            #if user is not the owner then return 404
            return render_error(:not_found, "Application '#{application_id}' not found", 101) if @domain and @domain.owner.id != @cloud_user.id
          end
          # if not application then lookup by domain and app name
          if @application.nil?  
            get_domain() 
            @application = Application.find_by(domain: @domain, canonical_name: Application.check_name!(application_id)) if @domain
          end
        end
    end
  end
end

