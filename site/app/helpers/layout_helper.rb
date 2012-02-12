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
      contents = collection.collect { |o| render options.merge(:object => o) }.join("</li><li class='span3'>")
      "<ul class='thumbnails'><li>#{contents}</li></ul>"
    end
  end
end
