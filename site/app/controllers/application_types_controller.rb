class ApplicationTypesController < ConsoleController

  def index
    types = ApplicationType.all :as => session_user

    types.sort!{ |a,b| a.name <=> b.name }

    # hack to make JBoss EAP show up before JBoss AS
    # we need to bubble it up inplace
    if index = types.index{ |t| t.id.start_with? 'jbosseap' }
      types.unshift types.delete_at(index)
    end

    @template_types, @framework_types = types.partition{ |t| t.template }

  end

  def show
    @application_type = ApplicationType.find params[:id], :as => session_user
    user_default_domain rescue nil
    @application = Application.new :as => session_user

    # hard code for now but we want to get this from the server eventually
    @gear_sizes = ["small"] # gear size choice only shows if there is more than
                            # one option
  end
end
