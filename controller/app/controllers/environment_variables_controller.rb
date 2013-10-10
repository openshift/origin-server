class EnvironmentVariablesController < BaseController
  include RestModelHelper
  before_filter :get_application
  action_log_tag_resource :environment_variable

  # GET /application/[id]/environment-variables
  # GET /domain/[domain_name]/application/[application_name]/environment-variables
  def index
    authorize! :view_environment_variables, @application

    rest_env_vars = []
    @application.list_user_env_variables.each do |name, value|
      rest_env_vars << get_rest_environment_variable({'name' => name, 'value' => value})
    end
    render_success(:ok, "environment-variables", rest_env_vars, "Listing environment variables for application #{@application.name}")
  end

  # GET /application/[application_id]/environment-variable/[name]
  # GET /domain/[domain_name]/application/[application_name]/environment-variable/[name]
  def show
    authorize! :view_environment_variables, @application

    name = params[:id].presence

    env_hash = @application.list_user_env_variables([name])
    return render_error(:unprocessable_entity, "Environment name '#{name}' not found in application", 189) unless env_hash[name]
    env_var = {'name' => name, 'value' => env_hash[name]}
    render_success(:ok, "environment-variable", get_rest_environment_variable(env_var),
                   "Showing environment variable '#{name}' for application #{@application.name}")
  end

  # POST /application/[application_id]/environment-variables
  # POST /domain/[domain_name]/application/[application_name]/environment-variables
  def create
    authorize! :change_environment_variables, @application

    name = params[:name].presence
    user_env_vars = params[:environment_variables].presence

    if (user_env_vars.present? && name) or (!user_env_vars.present? && !name)
      return render_error(:unprocessable_entity, "Specify parameters 'name'/'value' or 'environment_variables'", 191)
    end
    if name
      match = /\A([a-zA-Z_][\w]*)\z/.match(name)
      return render_error(:unprocessable_entity, "Name can only contain letters, digits and underscore and can't begin with a digit.", 194, "name") if match.nil?
      return render_error(:unprocessable_entity, "Value not specified for environment variable '#{name}'", 190, "value") unless params.has_key?(:value)
      value = params[:value]
      env_hash = @application.list_user_env_variables([name])
      return render_error(:unprocessable_entity, "Environment name '#{name}' already exists in application", 192) if env_hash[name]

      env_var = {'name' => name, 'value' => value}
      result = @application.patch_user_env_variables([env_var])
      rest_env_var = get_rest_environment_variable(env_var)
      return render_success(:created, "environment-variable", rest_env_var, "Added environment variable '#{name}' to application #{@application.name}", result)
    else
      Application.validate_user_env_variables(user_env_vars)
      result = @application.patch_user_env_variables(user_env_vars)
      set_vars, unset_vars = Application.sanitize_user_env_variables(user_env_vars)
      rest_env_vars = set_vars.map {|ev| get_rest_environment_variable(ev)}
      return render_success(:created, "environment-variables", rest_env_vars, "Patched environment variables for application #{@application.name}", result)
    end
  end

  # PUT /application/[application_id]/environment-variable/[name]
  # PUT /domain/[domain_name]/application/[application_name]/environment-variable/[name]
  def update
    authorize! :change_environment_variables, @application

    name = params[:id].presence

    return render_error(:unprocessable_entity, "Value not specified for environment variable '#{name}'", 190, "value") unless params.has_key?(:value)
    value = params[:value]
    env_hash = @application.list_user_env_variables([name])
    return render_error(:unprocessable_entity, "Environment name '#{name}' not found in application", 189) unless env_hash[name]

    env_var = {'name' => name, 'value' => value}
    result = @application.patch_user_env_variables([env_var])
    rest_env_var = get_rest_environment_variable(env_var)
    render_success(:ok, "environment-variable", rest_env_var, "Updated environment variable '#{name}' in application #{@application.name}", result)
  end

  # DELETE /application/[application_id]/environment-variable/[name]
  # DELETE /domain/[domain_name]/application/[application_name]/environment-variable/[name]
  def destroy
    authorize! :change_environment_variables, @application

    name = params[:id].presence

    result = @application.patch_user_env_variables([{'name' => name}])
    status = requested_api_version <= 1.4 ? :no_content : :ok
    render_success(status, nil, nil, "Removed environment variable '#{name}' from application #{@application.name}", result)
  end
end
