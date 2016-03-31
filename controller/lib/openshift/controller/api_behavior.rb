module OpenShift
  module Controller
    module ApiBehavior
      extend ActiveSupport::Concern

      API_VERSION = 1.7
      SUPPORTED_API_VERSIONS = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7]

      included do
        before_filter ->{ Mongoid.identity_map_enabled = true }
        before_filter :default_format_json
      end

      protected
        attr :requested_api_version

        def default_format_json
          request.format ||= 'json'
        end

        def check_version
          version = catch(:version) do
            "#{request.accept},#{request.env['CONTENT_TYPE']}".split(',').each do |mime_type|
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
            logger.debug "API version #{version}"
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
          raise OpenShift::UserException.new("Invalid value '#{param_value}'. Valid options: [true, false]", 167)
        end

        def get_includes
          @includes ||=
            if params[:include].is_a? String
              params[:include].split(',')
            elsif params[:include].is_a? Array
              params[:include].map(&:to_s)
            else
              []
            end
        end

        def if_included(sym, default=nil, &block)
          if get_includes.any?{ |i| i == sym.to_s }
            block_given? ? yield : true
          else
            default
          end
        end

        def id?(s)
          s.present? && s =~ /\A[\da-fA-F]{20,36}\Z/
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

        def get_domain(id=nil)
          id ||= params[:domain_id].presence
          @domain = Domain.accessible(current_user).find_by(canonical_namespace: Domain.check_name!(id.presence).downcase)
        end

        def find_or_create_domain!(id=nil)
          get_domain(id)
        rescue Mongoid::Errors::DocumentNotFound
          raise if params[:domain_id].blank?
          begin
            if OpenShift::ApplicationContainerProxy.blacklisted? params[:domain_id]
              raise OpenShift::UserException.new("Namespace is not allowed.  Please choose another.", 106) 
            end
            @domain = Domain.create!(namespace: params[:domain_id], owner: current_user)
          rescue OpenShift::UserException => e
            e.field = 'domain_id'
            raise
          end
        end

        def get_application
          domain_id = params[:domain_id].presence || params[:domain_name].presence
          domain_id = domain_id.to_s.downcase if domain_id
          application_id = params[:application_id].presence || params[:id].presence || params[:application_name].presence || params[:name].presence
          application_id = application_id.to_s if application_id

          @application =
            if domain_id.nil?
              Application.accessible(current_user).find(application_id)
            else
              domain_id = Domain.check_name!(domain_id).downcase
              begin
                Application.accessible(current_user).find_by(domain_namespace: domain_id, canonical_name: Application.check_name!(application_id).downcase)
              rescue Mongoid::Errors::DocumentNotFound
                # ensure a domain not found exception is raised
                Domain.accessible(current_user).find_by(canonical_namespace: domain_id)
                raise
              end
            end
        end

        def get_team(id=nil)
          id ||= params[:team_id].presence
          @team = Team.accessible(current_user).find(id)
        end

        def authorize!(permission, resource, *resources)
          Ability.authorize!(current_user, current_user.scopes, permission, resource, *resources)
        end
        def authorized?(permissions, resource, *resources)
          Ability.authorized?(current_user, current_user.scopes, permissions, resource, *resources)
        end

        def check_input
          unless support_valid_encoding?
            # ruby 1.8.7 does have valid_encoding? method so catching the exception and logging
            Rails.logger.warn "Could not validate request parameters encoding when running under MRI1.8"
            return
          end
          check = lambda do |value|
            err_message = "Only valid UTF-8 encoded inputs are accepted"
            case value
              when String then render_error(:bad_request, err_message) unless value.valid_encoding?
              when Array then value.each(&check)
              when Hash then value.each { |k, v| check.call(k.to_s) && check.call(v) }
            end
          end
          params.each_value(&check)
        end

        def support_valid_encoding?
          String.new.respond_to?('valid_encoding?')
        end
    end
  end
end

