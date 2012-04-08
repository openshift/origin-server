module CommunityHelper

  # Given a relative path within the user guide, display the topic
  def community_url
    "http://www.redhat.com/openshift/community"
  end

  def newsletter_signup_url
    'http://makara.nurturehq.com/makara/newsletter_signup.html'
  end

  def irc_web_url
    'http://webchat.freenode.net/?randomnick=1&channels=openshift&uio=d4'
  end

  def link_to_irc
    link_to "IRC", irc_web_url
  end

  def openshift_twitter_hashtag_url
    'http://twitter.com/#!/search/%23OpenShift'
  end

  def openshift_twitter_url
    'http://www.twitter.com/#!/openshift'
  end

  def openshift_blog_url
    'https://www.redhat.com/openshift/blogs'
  end

  def open_bug_url
    'https://bugzilla.redhat.com/enter_bug.cgi?product=OpenShift%20Express'
  end

  def openshift_github_url
    'https://github.com/openshift'
  end

  def openshift_github_project_url(project)
    "https://github.com/openshift/#{project}"
  end

  def mailto_openshift_url
    'mailto:openshift@redhat.com'
  end

  def link_to_account_mailto
    link_to "openshift@redhat.com", mailto_openshift_url
  end

end
