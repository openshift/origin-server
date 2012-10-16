require 'uri'

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

  def present?
    !(name.nil? or name.blank?) or !(type.nil? or type.blank?)
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

  def index
    # replace domains with Applications.find :all, :as => current_user
    # in the future
    #domain = Domain.find :one, :as => current_user rescue nil
    user_default_domain rescue nil
    return redirect_to application_types_path, :notice => 'Create your first application now!' if @domain.nil? || @domain.applications.empty?

    @applications_filter = ApplicationsFilter.new params[:applications_filter]
    @applications = @applications_filter.apply(@domain.applications)
  end

  def destroy
    @domain = Domain.find :one, :as => current_user
    @application = @domain.find_application params[:id]
    if @application.destroy
      redirect_to applications_path, :flash => {:success => "The application '#{@application.name}' has been deleted"}
    else
      render :delete
    end
  end

  def delete
    #@domain = Domain.find :one, :as => current_user
    user_default_domain
    @application = @domain.find_application params[:id]

    @referer = application_path(@application)
  end

  def new
    redirect_to application_types_path
  end

  def create
    app_params = params[:application]

    @application_type = ApplicationType.find app_params[:application_type]

    @application = Application.new app_params
    @application.as = current_user

    @gear_sizes = ["small"]
    # opened bug 789763 to track simplifying this block - with domain_name submission we would
    # only need to check that domain_name is set (which it should be by the show form)
    @domain = Domain.find :first, :as => current_user
    unless @domain
      @domain = Domain.create :name => @application.domain_name, :as => current_user
      unless @domain.persisted?
        logger.debug "Unable to create domain, #{@domain.errors.inspect}"
        @application.valid? # set any errors on the application object
        #FIXME: Ideally this should be inferred via associations between @domain and @application
        @domain.errors.values.flatten.uniq.each {|e| @application.errors.add(:domain_name, e) }
        logger.debug "Found errors during domain creation #{@application.errors.inspect}"
        return render 'application_types/show'
      end
    end

    @application.domain = @domain
    if @application_type.template
      @application.template = @application_type.template.uuid
    else
      @application.cartridge = @application_type.cartridge || @application_type.id
    end

    if @application.save
      messages = @application.remote_results

      if @application_type.template
        t = @application_type.template
        messages << t.credentials_message if t.credentials
      end

      redirect_to get_started_application_path(@application, :wizard => true, :template => (@application_type.template.present? || nil)), :flash => {:info_pre => messages}
    else
      logger.debug @application.errors.inspect
      render 'application_types/show'
    end
  end

  def show
    #@domain = Domain.find :one, :as => current_user
    user_default_domain
    @application = @domain.find_application params[:id]

    async{ @gear_groups = @application.cartridge_gear_groups }
    async{ @gear_groups_with_state = @application.gear_groups }
    join!(30)

    @gear_groups.each{ |g| g.merge_gears(@gear_groups_with_state) }

    sshkey_uploaded?
  end

  def get_started
    #@domain = Domain.find :one, :as => current_user
    user_default_domain
    @application = @domain.find_application params[:id]

    @wizard = !params[:wizard].nil?
    @template = !params[:template].nil?
    sshkey_uploaded?
  end
end
