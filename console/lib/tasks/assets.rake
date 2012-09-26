class GenerateConsoleViewTask < Rake::TaskLib
  attr_accessor :layout, :views

  def initialize(name)
    yield self if block_given?
    define(name)
  end
  def define(name)
    task name => [:environment] do
      views.each_pair do |view_path, file|
        File.open(File.join(Rails.root, 'public', file), 'w') do |f|
          f.write(render(view_path))
        end
      end
    end
  end
  
  protected
    def render(template)
      view.render :template => template.dup, :layout => layout
    end
    def controller_class
      ConsoleController
    end
    def controller
      controller = controller_class.new
      controller.request = ActionDispatch::TestRequest.new
      controller
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
           {:host => 'localhost'}
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
  GenerateConsoleViewTask.new(:public_pages) do |t|
    t.layout = 'layouts/console'
    t.views = {
      'console/not_found' => '404.html',
      'console/error'     => '500.html',
    }
  end
end
