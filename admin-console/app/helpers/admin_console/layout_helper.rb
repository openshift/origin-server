require 'enumerator'
module AdminConsole
  module LayoutHelper

    def navigation_tabs(options={}, &block)
      content = capture(&block)
      content_tag(:ul, content, :class => 'nav')
    end

    def navigation_tab(name, options={})
      action = options[:action]
      active = controller.active_tab == name || (name.to_s == controller_name) && (action.nil? || action.to_s == controller.action_name)
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

    def progress_bar(percent, classes = [])
      percent = 0.25 if percent < 0.25 #make bar always visible
      percent = 100 if percent > 100
      bar = content_tag(:div, "", :class => "bar", :style => "width: #{percent}%;")
      classes << "progress"
      content_tag(:div, bar, :class => classes.join(' '))
    end

    def progress_bar_with_thresholds(percent, warning, error)
      percent = 0.25 if percent < 0.25 #make bar always visible
      warning = 0.25 if warning < 0.25 #make bar always visible
      error = 0.25 if error < 0.25 #make bar always visible
      percent = 100 if percent > 100
      bars = []
      bars << content_tag(:div, "", :class => "bar bar-success", :style=> "width: #{[percent,warning].min}%;")
      bars << content_tag(:div, "", :class => "bar bar-warning", :style=> "width: #{[percent - warning, error - warning].min}%;") unless percent < warning
      bars << content_tag(:div, "", :class => "bar bar-danger", :style=> "width: #{percent - error}%;") unless percent < error
      content_tag(:div, bars.join.html_safe, :class => "progress")
    end

    def threshold_pct(threshold, total)
      return 0 if total == 0
      ((total - threshold) / total.to_f) * 100
    end

    def log_scale_percentage(perfect, actual, options = {})
      log_pct_increment = options[:log_pct_increment].present? ? options[:log_pct_increment] : 25
      log_base = options[:log_base].present? ? options[:log_base] : 10
      max_pct = options[:max_pct].present? ? options[:max_pct] : 100

      relative = (perfect-actual).abs
      return 0 if relative == 0

      log = Math.log(relative) / Math.log(log_base)
      log = log.ceil
      log = 1 if log == 0 # normalize when relative == 1
      log_position = (log - 1) * log_pct_increment # increases one log every log_pct_increment
      power = log_base ** log
      position = relative / power.to_f * log_pct_increment
      [max_pct, log_position + position].min
    end
  end
end
