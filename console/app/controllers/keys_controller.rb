class KeysController < ConsoleController
  def new
    @first = true if params[:first]
    @key = Key.new
  end

  def create
    @first = true if params[:first]
    @key ||= Key.new params[:key]
    @key.as = session_user

    if @key.save
      redirect_to (@first ? :back : account_path), :flash => {:success => 'Your public key has been created'} rescue redirect_to account_path
    else
      Rails.logger.debug @key.errors.inspect
      render :new
    end

  # If a key already exists with that name
  # FIXME When resource validation is added, we may need the server to return a unique code
  # for this condition with the error, and then this logic should be moved to Key.rescue_save_failure
  # which should throw a more specific exception Key::NameExists / Key::ContentExists
  rescue Key::DuplicateName
    if @first
      if @key.default?
        @key = Key.default(:as => session_user).load(params[:key])
      else
        @key.make_unique! "#{@key.name}%s"
      end
      raise if @retried
      @retried = true
      retry
    end
    @key.errors.add(:name, 'You have already created a key with that name')
    render :new
  end

  def destroy
    @key = Key.find params[:id], :as => session_user
    @key.destroy
    redirect_to account_path
  end
end
