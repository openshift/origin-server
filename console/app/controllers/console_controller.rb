class ConsoleController < Console.config.parent_controller.constantize
  include Console::Auth::Passthrough unless Console.config.disable_passthrough
  include DomainAware
  include SshkeyAware

  layout 'console'

  before_filter :authenticate_user!

  rescue_from ActiveResource::ConnectionError, :with => :generic_error
  rescue_from ActiveResource::ResourceNotFound, :with => :page_not_found
  rescue_from RestApi::ResourceNotFound, :with => :resource_not_found

  def active_tab
    nil
  end

  protected
    def resource_not_found(e)
      alternatives = if Application == e.model
                       @domain.applications.map do |app|
                         ["Application #{app.name}", application_path(app)]
                       end.tap do |links|
                         links << ['Create a new application', new_application_path] if links.empty?
                       end if @domain rescue nil
                     elsif ApplicationType == e.model
                        [['See other application types', application_types_path]]
                     end
      page_not_found(e, e.message, alternatives)
    end

    def page_not_found(e=nil, message=nil, alternatives=nil)
      @reference_id = request.uuid
      logger.warn "Page not found - Reference ##{@reference_id}"
      @message, @alternatives = message, alternatives
      render 'shared/not_found'
    end

    def generic_error(e=nil, message=nil, alternatives=nil)
      @reference_id = request.uuid
      logger.error "Unhandled exception reference ##{@reference_id}: #{e.message}\n#{e.backtrace.join("\n  ")}"
      @message, @alternatives = message, alternatives
      render 'shared/error'
    end

  private
    def help
    end
end
