class GenerateConsoleViewTask < Rake::Task
  def initialize(task_name, app, &block)
    super
    prerequisites << :environment
    instance_eval &block
  end
  protected
    attr_accessor :template, :layout

    def render
      view.render :template => template, :layout => layout
    end
    def controller_class
      ConsoleController
    end
    def controller
      controller = controller_class.new
      controller.request = ActionDispatch::TestRequest.new
    end
    def view
      view = ActionView::Base.new(ActionController::Base.view_paths, {}, controller)

      routes = Rails.application.routes
      routes.default_url_options = {:host => 'localhost'}

      view.class_eval do
        include routes.url_helpers

        def protect_against_forgery?
          false
        end

        def default_url_options
           {host: 'localhost'}
        end
      end
      view.class_eval do
        include Console::LayoutHelper
        include Console::HelpHelper
        include Console::Html5BoilerplateHelper
        include Console::ModelHelper
        include Console::SecuredHelper
        include Console::CommunityHelper
        include Console::ConsoleHelper
      end
      view
    end
end

namespace :assets do
  GenerateConsoleViewTask.new(:404) do
    
  end
  task :public_pages => [] do
    {
      '404.html' => 'console/not_found',
      '500.html' => 'console/error',
    }.each_pair do |file, view|
      File.open(File.join(Rails.root, 'public', file), 'w') do |f|
        f.write(action_view.render :template => view, :layout => 'layouts/console')
      end
    end
  end
end
