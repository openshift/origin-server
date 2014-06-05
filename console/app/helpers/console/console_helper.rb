module Console::ConsoleHelper

  #FIXME: Replace with real isolation of login state
  def logout_path
    nil
  end

  def outage_notification
  end

  def product_branding
    [
      image_tag(Console.config.env(:PRODUCT_LOGO, "/assets/logo-origin.svg"), :alt => Console.config.env(:PRODUCT_TITLE, "OpenShift Origin"))
    ].join.html_safe
  end

  def product_title
    Console.config.env(:PRODUCT_TITLE, 'OpenShift Origin')
  end
end
