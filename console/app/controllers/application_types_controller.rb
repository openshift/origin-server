class ApplicationTypesController < ConsoleController
  include Console::ModelHelper
  include CostAware

  def index
    @capabilities = user_capabilities

    if (create_warning = available_gears_warning(user_writeable_domains))
      flash.now[:warning] = create_warning
    end

    @browse_tags = [
      ['Java', :java],
      ['PHP', :php],
      ['Ruby', :ruby],
      ['Python', :python],
      ['Node.js', :nodejs],
      ['Perl', :perl],
      nil,
      ['All web cartridges', :cartridge],
      ['All instant applications', :instant_app],
      nil,
      ['xPaaS', :xpaas],
      ['Blogs', :blog],
      ['Content management systems', :cms],
      #['MongoDB', :mongo],
    ]

    if @tag = params[:tag].presence
      types = ApplicationType.tagged(@tag, :as => current_user)
      ApplicationType.set_display_unique_name(types)


      @type_groups = [["Tagged with #{Array(@tag).to_sentence}", types.sort!]]

      render :search
    elsif @search = params[:search].presence
      types = ApplicationType.search(@search, :as => current_user)
      ApplicationType.set_display_unique_name(types)

      @type_groups = [["Matches search '#{@search}'", types]]

      render :search
    else
      types = ApplicationType.all(:as => current_user)
      ApplicationType.set_display_unique_name(types)

      @featured_types = types.select{ |t| t.tags.include?(:featured) }.sample(3).sort!
      groups, other = in_groups_by_tag(types, [:instant_app, :xpaas, :java, :php, :ruby, :python])
      groups.each do |g|
        g[2] = application_types_path(:tag => g[0])
        g[1].sort!
        g[0] = I18n.t(g[0], :scope => :types, :default => g[0].to_s.titleize)
      end
      @custom_types, other = other.partition{ |t| t.tags.include?(:custom) } if RestApi.download_cartridges_enabled?
      groups << ['Other types', other.sort!] unless other.empty?
      @type_groups = groups
    end
  end

  def show
    app_params = params[:application] || params
    app_type_params = params[:application_type] || app_params
    @unlock_cartridges = to_boolean(params[:unlock])

    @capabilities = user_capabilities :refresh => true
    @user_usage_rates = current_api_user.usage_rates

    @user_writeable_domains = user_writeable_domains :refresh => true
    @user_default_domain = user_default_domain rescue (Domain.new)
    @can_create = @capabilities.max_domains > user_owned_domains.length

    @compact = false # @domain.persisted?

    @application_type = params[:id] == 'custom' ?
      ApplicationType.custom(app_type_params) :
      ApplicationType.find(params[:id])

    @gear_sizes = new_application_gear_sizes(@user_writeable_domains, @capabilities, @application_type)

    if @application_type.valid_gear_sizes? && (@gear_sizes & @application_type.valid_gear_sizes).empty?
      flash.now[:error] = "Your account does not support gear sizes compatible with this cartridge. #{@application_type.display_name} can only run on the following gear sizes: #{@application_type.valid_gear_sizes.map(&:to_s).join(', ')}."
    end

    @regions = Region.cached.all

    @application = (@application_type >> Application.new(:as => current_user)).assign_attributes(app_params)
    @application.gear_profile = @gear_sizes.first unless @gear_sizes.include?(@application.gear_profile)
    @application.domain_name = app_params[:domain_name] || app_params[:domain_id] || @user_default_domain.name

    (@domain_capabilities, @domain_usage_rates, @is_domain_owner) = estimate_domain_capabilities(@application.domain_name, @user_writeable_domains, @can_create, @capabilities, @user_usage_rates)

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

    if @application.name.blank? && (suggest = Application.suggest_name_from(@cartridges))
      @application.name = suggest
      @suggesting_name = true
    end

    if (create_warning = available_gears_warning(@user_writeable_domains))
      flash.now[:error] = create_warning
    end

    user_default_domain rescue nil
  end

  def estimate
    app_params = params[:application] || params
    app_type_params = params[:application_type] || app_params

    scales = to_boolean(app_params[:scale])
    application_type = params[:id] == 'custom' ?
      ApplicationType.custom(app_type_params) :
      ApplicationType.find(params[:id])
    cartridges = to_boolean(params[:unlock]) ? {} : (application_type.matching_cartridges.first rescue {})
    application = (application_type >> Application.new(:as => current_user)).assign_attributes(app_params)

    begin
      domain = Domain.find(app_params[:domain_name], :as => current_user, :params => {:include => :application_info})
      capabilities = domain.capabilities
      usage_rates = domain.usage_rates
      owner = domain.owner?
    rescue RestApi::ResourceNotFound => e
      # Assume this is a new domain name being entered, so use the user's capabilities
      capabilities = user_capabilities
      usage_rates = current_api_user.usage_rates
      owner = true
    end

    render :text => gear_increase_indicator(cartridges, scales, application.gear_profile, false, capabilities, usage_rates, owner)
  rescue => e
    logger.error $!
    render :text => "An error has occurred", :status => 500
  end

  protected
    def active_tab
      :applications
    end  
end
