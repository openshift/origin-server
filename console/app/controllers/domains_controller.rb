class DomainsController < ConsoleController
  def index
    @domains = Domain.find(:all, :as => current_user) rescue redirect_to(new_domain_path)
  end

  def show
    @domain = Domain.find(params[:id].to_s, :as => current_user)
  end

  def new
    @domain = Domain.new
    @referrer = valid_referrer(params[:then] || params[:redirectUrl] || request.referrer)
  end

  def create
    @domain = Domain.new params[:domain]
    @domain.as = current_user

    @referrer = valid_referrer(params[:then] || params[:redirectUrl])

    if @domain.save
      if @referrer.present? and params[:domain_param].present?
        begin
          puts "@referrer = #{@referrer}"
          u = URI(@referrer)
          puts "u = #{u.inspect}"
          q = Rack::Utils.parse_query u.query
          puts "q = #{q.inspect}"
          q[params[:domain_param]] = @domain.name
          puts "q = #{u.inspect}"
          u.query = q.to_query
          puts "u = #{u.inspect}"
          @referrer = u.to_s
          puts "@referrer = #{@referrer}"
        rescue Exception => e
          Rails.logger.debug "Error replacing domain param: #{e}\n#{e.backtrace.join("\n  ")}"
        end
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
    @domain.attributes = params[:domain]
    if @domain.save
      redirect_to settings_path, :flash => {:success => 'Your domain has been changed.  Your public URLs will now be different'}
    else
      render :edit
    end
  end

  protected
    def active_tab
      :settings unless ['show', 'index'].include? action_name
    end
end
