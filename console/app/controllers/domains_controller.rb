class DomainsController < ConsoleController
  def index
    @domains = Domain.find(:all, :params => {:include => :application_info}, :as => current_user)
    redirect_to(new_domain_path) and return if @domains.blank?
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
      if @referrer and (domain_param = params[:domain_param]).present?
        @referrer = rewrite_url(@referrer, { domain_param => @domain.name }) rescue nil
      end
      redirect_to @referrer || settings_path, :flash => {:success => "The domain '#{@domain.name}' has been created"}
    else
      render :new
    end
  end

  def edit
    @domain = Domain.find(params[:id].to_s, :as => current_user)
  end

  def update
    @domain = Domain.find(params[:id].to_s, :as => current_user)
    @domain.attributes.merge!(params[:domain]) if params[:domain]

    if @domain.save or @domain.has_exit_code?(133)
      redirect_to domain_path(@domain), :flash => {:success => @domain.messages.first.presence || "The domain '#{@domain.name}' has been updated."}
    else
      render :edit
    end
  end

  def delete
    @domain = Domain.find(params[:id].to_s, :params => {:include => :application_info}, :as => current_user)
    if @domain.application_count > 0
      flash[:info] = "All applications must be removed from this domain before it can be deleted"
      redirect_to domain_path(@domain)
    end
  end

  def destroy
    @domain = Domain.find(params[:id].to_s, :params => {:include => :application_info}, :as => current_user)
    if @domain.destroy
      redirect_to settings_path, :flash => {:success => "The domain '#{@domain.name}' has been deleted"}
    else
      render :delete
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
