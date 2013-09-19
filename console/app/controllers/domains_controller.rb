class DomainsController < ConsoleController
  def index
    @domains = Domain.find(:all, :params => {:include => :application_info}, :as => current_user) rescue redirect_to(new_domain_path)
    @capabilities = user_capabilities :refresh => true
    @can_create = @capabilities.max_domains > user_owned_domains.length
  end

  def show
    @domain = Domain.find(params[:id].to_s, :params => {:include => :application_info}, :as => current_user)
    @capabilities = user_capabilities
  end

  def new
    @domain = Domain.new
    @referrer = valid_referrer(params[:then])
  end

  def create
    @domain = Domain.new params[:domain]
    @domain.as = current_user

    @referrer = valid_referrer(params[:then])

    if @domain.save
      if @referrer and (domain_param = params[:domain_param])
        @referrer = rewrite_url(@referrer, { domain_param => @domain.name }) rescue nil
      end
      redirect_to @referrer || settings_path, :flash => {:success => "The domain '#{@domain.name}' has been created"}
    else
      render :new
    end
  end

  def edit
    @domain = Domain.find(:one, :as => current_user) rescue redirect_to(new_domain_path)
  end

  def update
    @domain = Domain.find(:one, :as => current_user)
    @domain.attributes.merge!(params[:domain]) if params[:domain]

    if @domain.save or @domain.has_exit_code?(133)
      redirect_to domain_path(@domain), :flash => {:success => @domain.messages.first.presence || "The domain '#{@domain.name}' has been updated."}
    else
      render :edit
    end
  end

  protected
    def active_tab
      :settings unless ['show', 'index'].include? action_name
    end

    def rewrite_url(url, query)
      url = URI(url) unless url.is_a? URI
      url.query = Rack::Utils.parse_query(url.query).merge(query).select {|k,v| v != nil }.to_query
      url.to_s
    end
end
