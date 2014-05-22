module Console::CommunityHelper

  def irc_web_url
    Console.config.env(:IRC_WEB_URL, 'http://webchat.freenode.net/?randomnick=1&channels=openshift&uio=d4')
  end

  def link_to_irc
    link_to "IRC", irc_web_url
  end

  def openshift_twitter_hashtag_url
    Console.config.env(:OPENSHIFT_TWITTER_HASHTAG_URL, 'http://twitter.com/search/%23OpenShift')
  end

  def openshift_twitter_url
    Console.config.env(:OPENSHIFT_TWITTER_URL, 'http://twitter.com/openshift')
  end

  def openshift_ops_twitter_url
    Console.config.env(:OPENSHIFT_OPS_TWITTER_URL, 'http://twitter.com/openshift_ops')
  end

  def open_bug_url
    Console.config.env(:OPEN_BUG_URL, 'https://bugzilla.redhat.com/enter_bug.cgi?product=OpenShift%20Origin')
  end

  def openshift_github_url
    Console.config.env(:OPENSHIFT_GITHUB_URL, 'https://github.com/openshift')
  end

  def stack_overflow_url
    Console.config.env(:STACK_OVERFLOW_URL, 'http://stackoverflow.com/questions/tagged/openshift/')
  end

  def stack_overflow_link
    link_to "StackOverflow", stack_overflow_url
  end

  def client_tools_url
    openshift_github_project_url Console.config.env(:GITHUB_CLIENT_TOOLS_REPO, 'rhc')
  end

  def origin_server_url
    openshift_github_project_url Console.config.env(:GITHUB_ORIGIN_SERVER_REPO, 'origin-server')
  end

  def origin_server_source_path_url(path)
    "#{openshift_github_project_url('origin-server')}/tree/master/#{path}"
  end

  def cartridges_source_url
    origin_server_source_path_url 'cartridges'
  end

  def origin_server_srpm_url
   Console.config.env(:ORIGIN_SERVER_SRPM_URL, 'http://mirror.openshift.com/pub/openshift-origin/nightly/fedora-latest/latest/SRPMS/')
  end

  def openshift_github_project_url(project)
    "#{openshift_github_url}/#{project}"  
  end

  def red_hat_account_url
    Console.config.env(:RED_HAT_ACCOUNT_URL, 'https://www.redhat.com/wapps/ugc')
  end

  def contact_mail
    Console.config.env(:CONTACT_MAIL, 'openshift@redhat.com')
  end 

  def mailto_openshift_url
    'mailto:'+contact_mail
  end

  def link_to_account_mailto
    link_to contact_mail, mailto_openshift_url
  end

  def status_jsonp_url(id)
    status_js_path :id => id
  end

  def open_issues_jsonp_url(jsonp)
    open_issues_js_path :jsonp => jsonp
  end
end
