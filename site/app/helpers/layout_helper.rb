module LayoutHelper
  def navigation_tabs(options={}, &block)
    content = capture &block
    content_tag(:ul, content, :class => 'nav')
  end
  def navigation_tab(name, options={})
    action = options[:action]
    active = (name.to_s == controller_name) and (action.nil? or action.to_s == action_name)
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
    when :notice
      'alert alert-success'
    when :error
      'alert alert-error'
    when :info
      'alert alert-info'
    else
      'alert'
    end
  end
end
