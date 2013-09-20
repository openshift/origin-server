class ApplicationTypesController < ConsoleController
  include Console::ModelHelper
  include CostAware

  def index
    @capabilities = user_capabilities
    flash.now[:warning] = "Currently you do not have enough free gears available to create a new application. You can either scale down or delete existing applications to free up resources." unless @capabilities.gears_free? or user_writeable_domains.find(&:can_create_application?)

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
      ['Blogs', :blog],
      ['Content management systems', :cms],
      #['MongoDB', :mongo],
    ]

    if @tag = params[:tag].presence
      types = ApplicationType.tagged(@tag)
      @type_groups = [["Tagged with #{Array(@tag).to_sentence}", types.sort!]]

      render :search
    elsif @search = params[:search].presence
      types = ApplicationType.search(@search)
      @type_groups = [["Matches search '#{@search}'", types]]

      render :search
    else
      types = ApplicationType.all
      @featured_types = types.select{ |t| t.tags.include?(:featured) }.sample(3).sort!
      groups, other = in_groups_by_tag(types - @featured_types, [:instant_app, :java, :php, :ruby, :python])
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

    @user_default_domain = user_default_domain rescue (Domain.new)
    @user_writeable_domains = user_writeable_domains
    @can_create = @capabilities.max_domains > user_owned_domains.length

    @gear_sizes = (@capabilities.allowed_gear_sizes + @user_writeable_domains.map(&:capabilities).map(&:allowed_gear_sizes).flatten).uniq

    @compact = false # @domain.persisted?

    @application_type = params[:id] == 'custom' ?
      ApplicationType.custom(app_type_params) :
      ApplicationType.find(params[:id])

    @application = (@application_type >> Application.new(:as => current_user)).assign_attributes(app_params)
    @application.gear_profile = @gear_sizes.first unless @gear_sizes.include?(@application.gear_profile)
    @application.domain_name = app_params[:domain_name] || app_params[:domain_id] || @user_default_domain.name

    if (selected_domain = @user_writeable_domains.find {|d| d.name == @application.domain_name})
      @domain_capabilities = selected_domain.capabilities
      @is_domain_owner = selected_domain.owner?
    elsif @user_writeable_domains.length == 1
      @domain_capabilities = @user_writeable_domains.first.capabilities
      @is_domain_owner = @user_writeable_domains.first.owner?
    elsif @can_create and @user_writeable_domains.length == 0
      @domain_capabilities = @capabilities
      @is_domain_owner = true
    end

    # TODO: assign gear_profile from currently selected domain's allowed gear sizes if a domain is currently selected

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

    flash.now[:error] = "There are not enough free gears available to create a new application. You will either need to scale down or delete existing applications to free up resources." unless @capabilities.gears_free? or @user_writeable_domains.find(&:can_create_application?)
    
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
      owner = domain.owner?
    rescue RestApi::ResourceNotFound => e
      # Assume this is a new domain name being entered, so use the user's capabilities
      capabilities = user_capabilities
      owner = true
    end

    render :inline => gear_increase_indicator(cartridges, scales, application.gear_profile, false, capabilities, owner)
  rescue => e
    render :inline => e.message, :status => 500
  end
end
