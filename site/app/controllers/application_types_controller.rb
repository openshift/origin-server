class ApplicationTypesController < ConsoleController

  def index
    types = ApplicationType.all :as => session_user
    @template_types, types = types.partition{|t| t.template}
    @framework_types, types = types.partition { |t| t.categories.include?(:framework) }
    # hack to make JBoss EAP show up before JBoss AS
    # we need to bubble it up inplace
    eap_index = @framework_types.index { |t| t.id.start_with? "jbosseap" }
    eap = @framework_types[eap_index]
    while eap_index != 0 do
      left_sib = eap_index - 1
      @framework_types[eap_index] = @framework_types[left_sib]
      @framework_types[0] = eap if left_sib == 0
      eap_index = left_sib
    end
    @popular_types, types = types.partition { |t| t.categories.include?(:popular) }
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
