module LayoutHelper
  def navigation_tabs(options={}, &block)
    content = capture &block
    content_tag(:ul, content, :class => 'tabs')
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
end
