module HelpHelper

  # Given a relative path within the user guide, display the topic
  def user_guide_topic_url(topic)
    locale = 'en-US'
    "http://docs.redhat.com/docs/#{locale}/OpenShift_Express/2.0/html/User_Guide/#{topic}"
  end

  def community_topic_url(topic)
    "https://www.redhat.com/openshift/community/#{topic}"
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
  
  def manage_cartridges_user_guide_topic_url
    user_guide_topic_url 'sect-User_Guide-Adding_and_Managing_Database_Instances.html#form-User_Guide-Adding_Database_Back_Ends_to_Your_Applications-Command_Options_for_Controlling_Cartridges'
  end
  
  def git_user_guide_topic_url
    user_guide_topic_url 'sect-User_Guide-Application_Development-Deploying_Applications.html'
  end
  
  def install_cli_knowledge_base_url
    community_topic_url 'kb/kb-e1000/installing-openshift-express-client-tools-on-non-rpm-based-systems'
  end

  def post_to_forum_url
    community_topic_url 'forums/express'
  end
  
  def sync_git_with_remote_repo_knowledge_base_url
    community_topic_url 'kb/kb-e1006-sync-new-express-git-repo-with-your-own-existing-git-repo'
  end
  
  def rails_quickstart_guide
    community_topic_url 'kb/kb-e1005-ruby-on-rails-express-quickstart-guide'
  end
  
  def user_guide
    user_guide_topic_url 'index.html'
  end

  def git_homepage_url
    "http://git-scm.com/"
  end
end
