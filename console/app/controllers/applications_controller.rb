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

  # trigger synchronous module load 
  [GearGroup, Cartridge, Key, Application] if Rails.env.development?

  def index
    # replace domains with Applications.find :all, :as => current_user
    # in the future
    #domain = Domain.find :one, :as => current_user rescue nil
    if params[:test]
      @applications_filter = ApplicationsFilter.new params[:applications_filter]
      @applications = [
        Application.new({
          :name => 'widgetsprod', :app_url => "http://widgetsprod-widgets.rhcloud.com", :uuid => '1', :domain_id => 'widgets', :gear_profile => 'small', :gear_count => 2, 
          :cartridges => [
            Cartridge.new(:name => 'php-5.3',   :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :supported_scales_from => 1, :supported_scales_to => -1),
            Cartridge.new(:name => 'mysql-5.1', :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1),
            Cartridge.new(:name => 'haproxy-1.4', :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :colocated_with => ['php-5.3']),
          ], 
          :aliases => [Alias.new(:name => 'www.widgets.com'), Alias.new(:name => 'widgets.com')], 
          :members => [Member.new(:id => '1', :role => 'admin', :name => 'Alice', :owner => true)],
        }, true),
        Application.new({
          :name => 'widgets', :app_url => "http://widgets-widgets.rhcloud.com",:uuid => '2', :domain_id => 'widgets', :gear_profile => 'small', :gear_count => 1, 
          :cartridges => [
            Cartridge.new(:name => 'php-5.3',   :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :colocated_with => ['mysql-5.1']),
            Cartridge.new(:name => 'mysql-5.1', :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :colocated_with => ['php-5.3']),
          ], 
          :aliases => [], 
          :members => [Member.new(:id => '1', :role => 'admin', :name => 'Alice', :owner => true)]
        }, true),
        Application.new({
          :name => 'status', :app_url => "http://status-bobdev.rhcloud.com", :uuid => '3', :domain_id => 'bobdev', :gear_profile => 'small', :gear_count => 1, 
          :cartridges => [
            Cartridge.new(:name => 'ruby-1.9',   :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :colocated_with => []),
          ], 
          :aliases => [], 
          :members => [Member.new(:id => '1', :role => 'admin', :name => 'Alice', :owner => true)]
        }, true),
        Application.new({
          :name => 'statusp', :app_url => "http://statusp-bobdev.rhcloud.com",:uuid => '4', :domain_id => 'bobdev', :gear_profile => 'medium', :gear_count => 10, 
          :cartridges => [
            Cartridge.new(:name => 'ruby-1.9',   :gear_profile => 'medium', :current_scale => 9, :scales_from => 5, :scales_to => 10, :supported_scales_from => 1, :supported_scales_to => -1, :colocated_with => ['haproxy-1.4']),
            Cartridge.new(:name => 'haproxy-1.4', :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :colocated_with => ['ruby-1.9']),
          ], 
          :aliases => [], 
          :members => [Member.new(:id => '1', :role => 'admin', :name => 'Alice', :owner => true)]
        }, true),
        Application.new({
          :name => 'prodmybars', :app_url => "http://prodmybars-barco.rhcloud.com", :uuid => '5', :domain_id => 'barco', :gear_profile => 'small', :gear_count => 4, 
          :cartridges => [
            Cartridge.new(:name => 'python-2.7',   :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => -1, :supported_scales_from => 1, :supported_scales_to => -1, :colocated_with => ['haproxy-1.4']),
            Cartridge.new(:name => 'mongodb-2.2', :gear_profile => 'large', :current_scale => 3, :scales_from => 3, :scales_to => 3),
            Cartridge.new(:name => 'haproxy-1.4', :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :colocated_with => ['python-2.7']),
          ], 
          :aliases => [Alias.new(:name => 'api.mybars.com')], 
          :members => [Member.new(:id => '2', :role => 'admin', :name => 'Bob', :owner => true), Member.new(:id => '1', :role => 'edit', :name => 'Alice', :owner => false)]
        }, true),
        Application.new({
          :name => 'jenkins', :app_url => "http://jenkins-bobdev.rhcloud.com", :uuid => '3', :domain_id => 'bobdev', :gear_profile => 'small', :gear_count => 1, 
          :cartridges => [
            Cartridge.new(:name => 'jenkins-1.4',   :gear_profile => 'small', :current_scale => 1, :scales_from => 1, :scales_to => 1, :colocated_with => []),
          ], 
          :aliases => [], 
          :members => [Member.new(:id => '1', :role => 'admin', :name => 'Alice', :owner => true)]
        }, true),
      ]
      return
    end

    @applications = Application.find :all, :as => current_user
    #return redirect_to application_types_path, :notice => 'Create your first application now!' unless @applications.present?
    @applications_filter = ApplicationsFilter.new params[:applications_filter]
    @applications = @applications_filter.apply(@applications)

    if @applications.empty? && @applications_filter.blank?
      render :first_steps
    end
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
    @advanced = to_boolean(params[:advanced])
    @unlock_cartridges = to_boolean(params[:unlock])

    type = params[:application_type] || app_params[:application_type]
    domain_name = app_params[:domain_name].presence || app_params[:domain_id].presence

    @application_type = (type == 'custom' || !type.is_a?(String)) ?
      ApplicationType.custom(type) :
      ApplicationType.find(type)

    @capabilities = user_capabilities :refresh => true

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

    @user_default_domain = user_default_domain rescue nil
    @user_writeable_domains = user_writeable_domains

    flash.now[:error] = "You have no free gears.  You'll need to scale down or delete another application first." unless @capabilities.gears_free?
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
    @domain = user_default_domain
    app_id = params[:id].to_s

    async{ @application = Application.find(app_id, :as => current_user, :params => {:include => :cartridges}) }
    async{ @gear_groups_with_state = GearGroup.all(:as => current_user, :params => {:application_id => app_id}) }
    async{ sshkey_uploaded? }

    join!(30)

    @gear_groups = @application.cartridge_gear_groups
    @gear_groups.each{ |g| g.merge_gears(@gear_groups_with_state) }
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
  end
end
