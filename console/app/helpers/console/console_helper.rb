module Console::ConsoleHelper

  #FIXME: Replace with real isolation of login state
  def logout_path
    nil
  end

  def outage_notification
  end

  def product_branding
    content_tag(:span, nil, :class => 'brand-image')
  end

  def product_title
    'OpenShift Origin'
  end
end
