module Console::CommunityHelper

  def irc_web_url
    'http://webchat.freenode.net/?randomnick=1&channels=openshift&uio=d4'
  end

  def link_to_irc
    link_to "IRC", irc_web_url
  end

  def openshift_twitter_hashtag_url
    'http://twitter.com/search/%23OpenShift'
  end

  def openshift_twitter_url
    'http://twitter.com/openshift'
  end

  def openshift_ops_twitter_url
    'http://twitter.com/openshift_ops'
  end

  def open_bug_url
    'https://bugzilla.redhat.com/enter_bug.cgi?product=OpenShift%20Origin'
  end

  def openshift_github_url
    'https://github.com/openshift'
  end

  def stack_overflow_url
    'http://stackoverflow.com/questions/tagged/openshift/'
  end

  def stack_overflow_link
    link_to "StackOverflow", stack_overflow_url
  end

  def client_tools_url
    openshift_github_project_url 'rhc'
  end

  def origin_server_url
    openshift_github_project_url 'origin-server'
  end

  def origin_server_source_path_url(path)
    "#{openshift_github_project_url('origin-server')}/tree/master/#{path}"
  end

  def cartridges_source_url
    origin_server_source_path_url 'cartridges'
  end

  def origin_server_srpm_url
   "http://mirror.openshift.com/pub/openshift-origin/nightly/fedora-latest/latest/SRPMS/"
  end

  def openshift_github_project_url(project)
    "https://github.com/openshift/#{project}"
  end

  def red_hat_account_url
    'https://www.redhat.com/wapps/ugc'
  end

  def mailto_openshift_url
    'mailto:openshift@redhat.com'
  end

  def link_to_account_mailto
    link_to "openshift@redhat.com", mailto_openshift_url
  end

  def status_jsonp_url(id)
    status_js_path :id => id
  end

  def open_issues_jsonp_url(jsonp)
    open_issues_js_path :jsonp => jsonp
  end
end
