module ConsoleHelper

  def openshift_url(relative='')
    "https://openshift.redhat.com/app/#{relative}"
  end

  def legal_opensource_disclaimer_url
    openshift_url 'legal/opensource_disclaimer'
  end

  def root_path
    console_path
  end

  #FIXME: Replace with real isolation of login state
  def logout_path
    nil
  end

  def outage_notification
  end

  def session_user
    controller.session_user
  end
end
