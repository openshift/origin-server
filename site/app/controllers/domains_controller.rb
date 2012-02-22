class DomainsController < ConsoleController
  def new
    @domain = Domain.new
  end

  def create
    @domain = Domain.new params[:domain]
    @domain.as = session_user

    if @domain.save
      redirect_to account_path, :flash => {:success => 'Your domain has been created'}
    else
      render :new
    end
  end

  def edit
    @domain = Domain.first(:as => session_user)
    redirect_to new_domain_path unless @domain
  end

  def update
    @domain = Domain.first(:as => session_user).load(params[:domain])
    if @domain.save
      redirect_to account_path, :flash => {:success => 'Your domain has been changed.  Your public URLs will now be different'}
    else
      render :edit
    end
  end
end
