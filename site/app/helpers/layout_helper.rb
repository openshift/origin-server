require 'enumerator'

module LayoutHelper
  
  def navigation_tabs(options={}, &block)
    content = capture &block
    content_tag(:ul, content, :class => 'nav')
  end
  
  def navigation_tab(name, options={})
    action = options[:action]
    active = (name.to_s == controller_name) && (action.nil? || action.to_s == controller.action_name)
    content_tag(
      :li,
      link_to(
        options[:name] || ActiveSupport::Inflector.humanize(name),
        url_for({
          :action => action || :index,
          :controller => name
        })
      ),
      active ? {:class => 'active'} : nil)
  end

  #
  # Renders the flash only once.  In normal rails flow templates are rendered first
  # and so the flash will be displayed in the template - otherwise the layout has
  # an opportunity to render it.
  #
  def flashes
    return if @flashed_once || flash.nil?; @flashed_once = true
    render :partial => 'layouts/new_flashes', :locals => {:flash => flash}
  end

  def alert_class_for(key)
    case key
    when :success
      'alert alert-success'
    when :notice
      'alert alert-info'
    when :error
      'alert alert-error'
    when :info
      'alert alert-info'
    else
      Rails.logger.debug "Handling alert key #{key.inspect}"
      'alert'
    end
  end

  def render_thumbnails( collection, options )
    unless collection.empty?
      content_tag(
        :ul,
        collection.collect { |o| 
          content_tag(
            :li,
            render(options.merge(:object => o)).html_safe,
            :class => options[:grid] || 'span3'
          ) 
        }.join.html_safe,
        :class => 'thumbnails'
      )
    end
  end

  def breadcrumb_divider
    content_tag(:span, '/', :class => 'divider')
  end

  WizardStepsCreate = [
    {
      :name => 'Choose a type of application',
      :link => 'application_types_path'
    },
    {
      :name => 'Configure and deploy the application'
    },
    {
      :name => 'Next steps'
    }
  ]

  def wizard_steps_create(active, options={})
    wizard_steps(WizardStepsCreate, active, options)
  end
  def wizard_steps(items, active, options={})
    content_tag(
      :ol,
      items.each_with_index.map do |item, index|
        name = item[:name]
        content = if index < active and item[:link] and !options[:completed]
          link_to(name, send("#{item[:link]}")).html_safe
        else
          name
        end
        classes = if index < active
          'completed'
        elsif index == active
          'active'
        end
        content_tag(:li, content, :class => classes)
      end.join.html_safe,
      :class => 'wizard-steps'
    )
  end
end
