class ApplicationsFilter
  extend ActiveModel::Naming
  include ActiveModel::Serialization
  include ActiveModel::Conversion

  attr_accessor :name, 'type', :type_options
  def initialize(attributes={})
    attributes.each { |key,value| send("#{key}=", value) } unless attributes.nil?
  end

  def persisted?
    false
  end

  def active?
    @filtered
  end

  def blank?
    name.blank? and type.blank?
  end

  def apply(applications)
    @filtered = !applications.empty?
    @type_options = [['All','']]

    types = {}
    applications.select do |application|
      type = application.framework
      unless types.has_key? type
        @type_options << [application.framework_name, type]
        types[type] = true
      end

      ApplicationsFilter.wildcard_match?(@name, application.name) &&
        (@type.nil? or @type.blank? or @type == type)
    end
  end

  def self.wildcard_match?(search_str, value)
    return true if search_str.nil? || search_str.blank?

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
    /#{wildcard_re}/.match(value)
  end

end

class ApplicationsController < ConsoleController
  include AsyncAware

  include Console::ModelHelper

  # trigger synchronous module load 
  [GearGroup, Cartridge, Key, Application] if Rails.env.development?

  def index
    if params[:test]
      @applications = Fixtures::Applications.list
      @domains = Fixtures::Applications.list_domains
      (@applications + @domains).each{ |d| d.send(:api_identity_id=, '2') }
    else
      async{ @applications = Application.find :all, :as => current_user, :params => {:include => :cartridges} }
      async{ @domains = user_domains }
      join!(Console.config.background_request_timeout || 10)
    end

    render :first_steps and return if @applications.blank?

    @has_key = sshkey_uploaded?
    @user_owned_domains = user_owned_domains
    @empty_owned_domains = @user_owned_domains.select{ |d| d.application_count == 0 }
    @empty_unowned_domains = @domains.select{ |d| !d.owner? && d.application_count == 0 }
    @capabilities = user_capabilities(:refresh => true)
    @usage_rates = current_api_user.usage_rates
  end

  def destroy
    @application = Application.find(params[:id], :as => current_user)
    if @application.destroy
      redirect_to applications_path, :flash => {:success => "The application '#{@application.name}' has been deleted"}
    else
      render :delete
    end
  end

  def delete
    @application = Application.find(params[:id], :as => current_user)
    @referer = application_path(@application)
  end

  def new
    redirect_to application_types_path
  end

  def create
    app_params = params[:application] || params
    @unlock_cartridges = to_boolean(params[:unlock])

    type = params[:application_type] || app_params[:application_type]
    domain_name = app_params[:domain_name].presence || app_params[:domain_id].presence

    @application_type = (type == 'custom' || !type.is_a?(String)) ?
      ApplicationType.custom(type) :
      ApplicationType.find(type)

    @regions = Region.cached.all

    @capabilities = user_capabilities :refresh => true
    @user_usage_rates = current_api_user.usage_rates

    @application = (@application_type >> Application.new(:as => current_user)).assign_attributes(app_params)
    @application.domain_name = domain_name

    unless @unlock_cartridges
      begin
        @cartridges, @missing_cartridges = @application_type.matching_cartridges
        flash.now[:error] = "No cartridges are defined for this type - all applications require at least one web cartridge" unless @cartridges.present?
      rescue ApplicationType::CartridgeSpecInvalid
        logger.debug $!
        flash.now[:error] = "The cartridges defined for this type are not valid.  The #{@application_type.source} may not be correct."
      end
      @disabled = @missing_cartridges.present? || @cartridges.blank?
    end

    @user_writeable_domains = user_writeable_domains :refresh => true
    @user_default_domain = user_default_domain rescue nil
    @can_create = current_api_user.max_domains > user_owned_domains.length

    (@domain_capabilities, @domain_usage_rates, @is_domain_owner) = estimate_domain_capabilities(@application.domain_name, @user_writeable_domains, @can_create, @capabilities, @user_usage_rates)

    @gear_sizes = new_application_gear_sizes(@user_writeable_domains, @capabilities, @application_type)

    flash.now[:error] = out_of_gears_message unless @capabilities.gears_free? or @user_writeable_domains.find(&:can_create_application?)
    # opened bug 789763 to track simplifying this block - with domain_name submission we would
    # only need to check that domain_name is set (which it should be by the show form)
    if (valid = @application.valid?) # set any errors on the application object
      begin
        @domain = Domain.find domain_name, :as => current_user
        if @domain.editor?
          @application.domain = @domain
        else
          @application.errors.add(:domain_name, "You cannot create applications in the '#{domain_name}' namespace")
          valid = false
        end
      rescue RestApi::ResourceNotFound
        @domain = Domain.create :name => domain_name, :as => current_user
        if @domain.persisted?
          @application.domain = @domain
        else
          logger.debug "Unable to create domain, #{@domain.errors.to_hash.inspect}"
          #FIXME: Ideally this should be inferred via associations between @domain and @application
          @domain.errors.values.flatten.uniq.each {|e| @application.errors.add(:domain_name, e) }

          return render 'application_types/show'
        end
      end
    end


    begin
      if valid and @application.save
        messages = @application.remote_results
        redirect_to get_started_application_path(@application, :wizard => true), :flash => {:info_pre => messages}
      else
        logger.debug @application.errors.inspect
        render 'application_types/show'
      end
    rescue ActiveResource::TimeoutError
      redirect_to applications_path, :flash => {:error => "Application creation is taking longer than expected. Please wait a few minutes, then refresh this page."}
    end
  end

  def show
    if params[:test]
      @application = Fixtures::Applications.send(params[:test])
      @domain = Domain.new({:name => @application.domain_id}, true)
      @capabilities = Domain::Capabilities.new({:max_gears => 3})
      @capabilities.send(:max_gears=, params[:test_gears].to_i) if params[:test_gears]
      @gear_groups = @application.cartridge_gear_groups
      @gear_groups_with_state = @application.gear_groups
      @gear_groups.each{ |g| g.merge_gears(@gear_groups_with_state) }
      return
    end

    app_id = params[:id].to_s

    async{ @application = Application.find(app_id, :as => current_user, :params => {:include => :cartridges}) }
    async{ @gear_groups_with_state = GearGroup.all(:as => current_user, :params => {:application_id => app_id, :timeout => 3}) }
    async{ sshkey_uploaded? }

    join!(Console.config.background_request_timeout || 30)

    @capabilities = @application.domain.capabilities

    @gear_groups = @application.cartridge_gear_groups
    @gear_groups.each{ |g| g.merge_gears(@gear_groups_with_state) }
    #@environment_variables = @application.environment_variables
  end

  def get_started
    @application = Application.find(params[:id], :as => current_user)
    @wizard = params[:wizard].present?

    if !sshkey_uploaded? && !params[:ssh]
      @noflash = true; flash.keep
      @key = Key.new
      render :upload_key and return
    end
  end

  def upload_key
    @application = Application.find(params[:id], :as => current_user)
    @noflash = true; flash.keep
    @wizard = params[:wizard].present?

    @key ||= Key.new params[:key]
    @key.as = current_user

    if @key.save
      redirect_to get_started_application_path(@application, :ssh => 'no', :wizard => @wizard)
    else
      render :upload_key
    end
  rescue Key::DuplicateName
    redirect_to get_started_application_path(@application, :ssh => 'no', :wizard => @wizard)
  end
end
