class AuthorizationsController < ConsoleController

  def new
    @authorization = Authorization.new
    scope_definitions
  end

  def create
    @authorization = Authorization.new params[:authorization].slice(:note)
    @authorization.scope = Array(params[:authorization][:scopes]).map(&:strip).map(&:presence).compact.join(' ')
    @authorization.as = current_user
    scope_definitions

    if @authorization.save
      redirect_to authorization_path(@authorization), :flash => {:success => 'New authorization token created'}
    else
      render :new
    end
  end

  def show
    @authorization = Authorization.find params[:id], :as => current_user
    scope_definitions
  end

  def edit
    @authorization = Authorization.find params[:id], :as => current_user
    scope_definitions
  end

  def update
    @authorization = Authorization.find params[:id], :as => current_user
    @authorization.assign_attributes(params[:authorization].slice(:note))
    scope_definitions

    if @authorization.save
      redirect_to authorization_path(@authorization), :flash => {:success => 'Authorization updated'}
    else
      render :edit
    end
  end

  def destroy
    @authorization = Authorization.find params[:id], :as => current_user
    @authorization.destroy
    redirect_to settings_path, :flash => {:success => 'The authorization has been revoked'}
  end

  def destroy_all
    @authorization = Authorization.destroy_all :as => current_user
    redirect_to settings_path, :flash => {:success => 'All authorizations revoked'}
  end

  protected
    def scope_definitions
      @simple_scopes ||= begin
          @scope_definitions = RestApi.info.scopes
          @parameter_scopes, s = @scope_definitions.partition{ |s| s[:parameterized] }
          s
        end
    end

    def active_tab
      :settings
    end
end
