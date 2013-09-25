module Console::ConsoleHelper

  #FIXME: Replace with real isolation of login state
  def logout_path
    nil
  end

  def outage_notification
  end

  def product_branding
    [
      image_tag('/assets/logo-origin.svg', :alt => 'OpenShift Origin')
    ].join.html_safe
  end

  def product_title
    'OpenShift Origin'
  end
end
