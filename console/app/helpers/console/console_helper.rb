module Console::ConsoleHelper

  #FIXME: Replace with real isolation of login state
  def logout_path
    nil
  end

  def outage_notification
  end

  def product_branding
    [
      content_tag(:span, "OpenShift Origin", :class => 'brand-text headline'),
      content_tag(:span, nil, :class => 'brand-image')
    ].join.html_safe
  end

  def product_title
    'OpenShift Origin'
  end
end
