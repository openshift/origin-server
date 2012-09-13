class DomainsController < ConsoleController
  def new
    @domain = Domain.new
  end

  def create
    @domain = Domain.new params[:domain]
    @domain.as = current_user

    if @domain.save
      redirect_to account_path, :flash => {:success => 'Your domain has been created'}
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
      redirect_to account_path, :flash => {:success => 'Your domain has been changed.  Your public URLs will now be different'}
    else
      render :edit
    end
  end
end
