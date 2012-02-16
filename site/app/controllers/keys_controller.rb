class KeysController < ConsoleController
  def new
    @first = true if params[:first]
    @key = Key.new
  end

  def create
    @first = true if params[:first]
    @key = Key.new params[:key]
    @key.as = session_user

    if @key.save
      redirect_to :back, :flash => {:success => 'Your public key has been created'} rescue redirect_to account_path
    else
      render :new
    end
  end
end
