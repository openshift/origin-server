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
    @userinfo = ExpressUserinfo.new :rhlogin => session[:login],
                                    :ticket => session[:ticket]
    @userinfo.establish
    @app = ExpressApp.new

    @app_type_filter_value = ""
    @name_filter_value = ""

    if !params.nil?
      @app_type_filter_value = params[:app_type_filter]
      @name_filter_value = params[:name_filter]
    end

    @app_type_options = [["All", ""]]
    seen_app_types = {}
    @filtered_app_info = {}

    if !@userinfo.app_info.nil?
      @userinfo.app_info.each do |app_name, app|
        app_type = app['framework'].split('-')[0]
        if !seen_app_types.has_key? app_type
          @app_type_options << app_type
        end
        seen_app_types[app_type] = true

        # filter
        if wildcard_match? @name_filter_value, app_name
          if @app_type_filter_value.nil? || @app_type_filter_value == ""
            @filtered_app_info[app_name] = app
          elsif @app_type_filter_value == app_type 
            @filtered_app_info[app_name] = app
          end
        end
      end
    end
    render
  end

  def delete
    commit = params[:commit]
    app_params = params[:express_app]
    app_name = app_params[:app_name]
    cartridge = app_params[:cartridge]
 
    if commit == 'Delete'
      app_params[:rhlogin] = session[:login]
      app_params[:ticket] = cookies[:rh_sso]
      app_params[:password] = ''
      @app = ExpressApp.new app_params
      @app.ticket = session[:ticket]
      if @app.valid?
        @app.deconfigure
        if @app.errors[:base].blank?
          @userinfo = ExpressUserinfo.new :rhlogin => session[:login],
                                          :ticket => session[:ticket]
          @userinfo.establish
          # get message from the JSON
          @message = @app.message || I18n.t('express_api.messages.app_deleted')
          @message_type = :success
        else
          @message = @app.errors.full_messages.join("; ")
          @message_type = :error
        end
      else
        @message = @app.errors.full_messages.join("; ")
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
    @userinfo = ExpressUserinfo.new :rhlogin => session[:login],
                                    :ticket => session[:ticket]
    @userinfo.establish

    @app_name = params['app_name']
    if @app_name.nil?
      @message_type = :error
      @message = "No application specified"
    else
      app_info = @userinfo.app_info[@app_name]
      #raise app_info.inspect
      @app = ExpressApp.new :app_name => app_info['name'],
                            :cartridge => app_info['framework'],
                            :rhlogin => session[:login],
                            :ticket => session[:ticket]

      if !@app.valid?
        @message = @app.errors.full_messages.join("; ")
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
