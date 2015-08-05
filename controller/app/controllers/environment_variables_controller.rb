class EnvironmentVariablesController < BaseController
  include RestModelHelper
  before_filter :get_application
  action_log_tag_resource :environment_variable

  def index
    authorize! :view_environment_variables, @application

    rest_env_vars = []
    @application.list_user_env_variables.each do |name, value|
      rest_env_vars << get_rest_environment_variable({'name' => name, 'value' => value})
    end
    render_success(:ok, "environment-variables", rest_env_vars, "Listing environment variables for application #{@application.name}")
  end

  def show
    authorize! :view_environment_variables, @application

    name = params[:id].presence

    env_hash = @application.list_user_env_variables([name])
    return render_error(:not_found, "User environment variable named '#{name}' not found in application", 188) unless env_hash[name]
    env_var = {'name' => name, 'value' => env_hash[name]}
    render_success(:ok, "environment-variable", get_rest_environment_variable(env_var),
                   "Showing environment variable '#{name}' for application #{@application.name}")
  end

  def create
    authorize! :change_environment_variables, @application

    name = params[:name].presence
    user_env_vars = params[:environment_variables].presence

    if (user_env_vars.present? && name) or (!user_env_vars.present? && !name)
      return render_error(:unprocessable_entity, "Specify parameters 'name'/'value' or 'environment_variables'", 186)
    end
    if name
      match = /\A([a-zA-Z_][\w]*)\z/.match(name)
      return render_error(:unprocessable_entity, "Name can only contain letters, digits and underscore and can't begin with a digit.", 188, "name") if match.nil?
      return render_error(:unprocessable_entity, "Name must be 128 characters or less.", 188, "name") if name.length > 128
      return render_error(:unprocessable_entity, "Value not specified for environment variable '#{name}'", 190, "value") unless params.has_key?(:value)
      value = params[:value]
      return render_error(:unprocessable_entity, "Value must be 4096 characters or less.", 190, "value") if value.length > 4096
      return render_error(:unprocessable_entity, "Value cannot contain null characters.", 190, "value") if value.include? "\\000"
      env_hash = @application.list_user_env_variables([name])
      return render_error(:unprocessable_entity, "Environment variable named '#{name}' already exists in application", 188) if env_hash[name]

      env_var = {'name' => name, 'value' => value}
      Application.validate_user_env_variables([env_var])
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

  def update
    authorize! :change_environment_variables, @application

    name = params[:id].presence

    return render_error(:unprocessable_entity, "Value not specified for environment variable '#{name}'", 190, "value") unless params.has_key?(:value)
    value = params[:value]
    env_hash = @application.list_user_env_variables([name])
    return render_error(:not_found, "User environment variable named '#{name}' not found in application", 188) unless env_hash[name]

    env_var = {'name' => name, 'value' => value}
    Application.validate_user_env_variables([env_var])
    result = @application.patch_user_env_variables([env_var])
    rest_env_var = get_rest_environment_variable(env_var)
    render_success(:ok, "environment-variable", rest_env_var, "Updated environment variable '#{name}' in application #{@application.name}", result)
  end

  def destroy
    authorize! :change_environment_variables, @application

    name = params[:id].presence

    result = @application.patch_user_env_variables([{'name' => name}])
    status = requested_api_version <= 1.4 ? :no_content : :ok
    render_success(status, nil, nil, "Removed environment variable '#{name}' from application #{@application.name}", result)
  end
end
