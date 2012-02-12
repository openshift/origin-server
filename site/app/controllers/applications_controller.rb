require 'rest_api'

class ApplicationsController < ConsoleController

  @@max_tries = 5000
  @@exclude_carts = ['raw-0.1', 'jenkins-1.4']

  def wildcard_match?(search_str, value)
    if search_str.nil?
      return true
    end

    search_str.strip!
    if search_str == ""
      return true
    end

    if !(search_str =~ /\*/)
      search_str = "*" + search_str + "*"
    end

    # make the regexp safe
    wildcard_parse = search_str.split('*')
    wildcard_re = ""
    for element in wildcard_parse
      if element == ""
        wildcard_re += ".*"
      else
        wildcard_re += Regexp.escape(element)
      end
    end

    # check for wildcard as last char
    if search_str.ends_with? '*'
      wildcard_re += ".*"
    end

    wildcard_re = "^" + wildcard_re + "$"
    if /#{wildcard_re}/.match(value)
      return true
    else
      return false
    end
  end

  def index
    # new restful stuff
    # replace domains with Applications.find :all, :as => session_user
    # in the future
    @domain = Domain.first :as => session_user
    @applications = @domain.applications
    @app_type_filter_value = ""
    @name_filter_value = ""

    if !params.nil?
      @app_type_filter_value = params[:app_type_filter]
      @name_filter_value = params[:name_filter]
    end

    @app_type_options = [["All", ""]]
    seen_app_types = {}
    @filtered_app_info = {}

    if !@applications.nil?
      @applications.each do |app|
        app_type = app.framework.split('-')[0]
        if !seen_app_types.has_key? app_type
          @app_type_options << app_type
        end
        seen_app_types[app_type] = true

        # filter
        if wildcard_match? @name_filter_value, app.name
          if @app_type_filter_value.nil? || @app_type_filter_value == ""
            @filtered_app_info[app.name] = app
          elsif @app_type_filter_value == app_type
            @filtered_app_info[app.name] = app
          end
        end
      end
    end
    render
  end

  def delete
    commit = params[:commit]
    app_params = params[:application]
    app_name = params[:application_id]
    cartridge = app_params[:cartridge]

    if commit == 'Delete'
      @domain = Domain.first :as => session_user
      @application = @domain.get_application app_name
      if @application.nil?
        @message = "Application #{app_name} not found"
        @message_type = :error
      elsif @application.valid?
        @application.delete
        if @application.errors[:base].blank?
          # get message from the JSON
          @message = @application.message || I18n.t('express_api.messages.app_deleted')
          @message_type = :success
        else
          @message = @application.errors.full_messages.join("; ")
          @message_type = :error
        end
      else
        @message = @application.errors.full_messages.join("; ")
        @message_type = :error
      end

    else
      @message = "Deletion of application canceled"
      @message_type = :notice
    end

    respond_to do |format|
        flash[@message_type] = @message
        format.html { redirect_to applications_path }
        format.js { render :json => response }
    end
  end

  def confirm_delete
    @app_name = params[:application_id]

    if @app_name.nil?
      @message_type = :error
      @message = "No application specified"
    else
      @domain = Domain.first :as => session_user
      @application = @domain.get_application @app_name

      if @application.nil?
        @message = "Application #{app_name} not found"
        @message_type = :error
      elsif !@application.valid?
        @message = @application.errors.full_messages.join("; ")
        @message_type = :error
      end
    end

    respond_to do |format|
      if @message_type == :error
        flash[@message_type] = @message
        format.html { redirect_to applications_path }
        format.js { render :json => response }
      else
        return render 'applications/confirm_delete'
      end
    end
  end

  def new
    types = ApplicationType.find :all
    @framework_types, @application_types = types.partition { |t| t.categories.include?(:framework) }
  end
end
