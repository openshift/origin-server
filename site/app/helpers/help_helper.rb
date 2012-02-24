module HelpHelper

  # Given a relative path within the user guide, display the topic
  def user_guide_topic_url(topic)
    locale = 'en-US'
    "http://docs.redhat.com/docs/#{locale}/OpenShift_Express/2.0/html/User_Guide/#{topic}"
  end

  def ssh_key_user_guide_topic_url
    user_guide_topic_url 'sect-User_Guide-Managing_SSH_Keys.html'
  end
  
  def manage_app_cli_user_guide_topic_url
    user_guide_topic_url 'chap-User_Guide-Application_Development.html'
  end

  def deploy_hook_user_guide_topic_url
    user_guide_topic_url 'sect-User_Guide-Using_the_Jenkins_Embedded_Build_System-The_BuildDeploy_Process_in_OpenShift_Express.html'
  end

  def add_domains_user_guide_topic_url
    user_guide_topic_url 'sect-User_Guide-Creating_Applications-Creating_Applications_with_the_Command_Line_Interface.html'
  end

  def post_to_forum_url
    'https://www.redhat.com/openshift/community/forums/express'
  end

  def git_homepage_url
    "http://git-scm.com/"
  end
end
