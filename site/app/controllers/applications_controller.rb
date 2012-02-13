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

  @@max_tries = 5000
  @@exclude_carts = ['raw-0.1', 'jenkins-1.4']

  def index
    # new restful stuff
    # replace domains with Applications.find :all, :as => session_user
    # in the future
    domain = Domain.first :as => session_user
    applications = if domain.nil?
      []
    else
      domain.applications
    end

    @applications_filter = ApplicationsFilter.new params[:applications_filter]
    @applications = @applications_filter.apply(applications)
  end

  def delete
    commit = params[:commit]
    app_params = params[:application]
    app_name = params[:application_id]
    cartridge = app_params[:cartridge]

    if commit == 'Delete'
      @domain = Domain.first :as => session_user
      @application = @domain.find_application app_name
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
      @application = @domain.find_application @app_name

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
    redirect_to application_type_path(ApplicationType.find_empty)
  end

  def create
    app_params = params[:application]

    @application_type = ApplicationType.find app_params[:application_type]

    @application = Application.new app_params
    @application.as = session_user

    # opened bug 789763 to track simplifying this block - with domain_name submission we would
    # only need to check that domain_name is set (which it should be by the show form)
    @domain = Domain.find :first, :as => session_user
    unless @domain
      @domain = Domain.create :name => @application.domain_name, :as => session_user
      unless @domain.persisted?
        @application.valid? # set any errors on the application object
        return render 'application_types/show'
      end
    end

    @application.domain = @domain
    @application.cartridge = @application_type.cartridge || @application_type.id

    if @application.save
      redirect_to applications_path
    else
      render 'application_types/show'
    end
  rescue ActiveResource::ServerError => e
    Rails.logger.debug "Unable to create application, #{e.response.inspect}" if defined? e.response
    Rails.logger.debug "Unable to create application, #{e.response.body.inspect}" if defined? e.response.body
    @application.errors.add(:base, "Unable to create application")
    render 'application_types/show'
  end
end
