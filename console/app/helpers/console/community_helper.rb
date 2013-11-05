module Console::CommunityHelper

  def irc_web_url
    'http://webchat.freenode.net/?randomnick=1&channels=protonbox&uio=d4'
  end

  def link_to_irc
    link_to "IRC", irc_web_url
  end

  def protonbox_twitter_hashtag_url
    'http://twitter.com/search/%23ProtonBox'
  end

  def protonbox_twitter_url
    'http://twitter.com/protonbox'
  end

  def open_bug_url
    '#'
  end

  def protonbox_github_url
    'https://github.com/protonbox'
  end

  def stack_overflow_url
    'http://stackoverflow.com/questions/tagged/protonbox/'
  end

  def stack_overflow_link
    link_to "StackOverflow", stack_overflow_url
  end

  def client_tools_url
    protonbox_github_project_url 'pbox'
  end

  def origin_server_source_path_url(path)
    "#{protonbox_github_project_url('origin-server')}/tree/master/#{path}"
  end

  def cartridges_source_url
    origin_server_source_path_url 'cartridges'
  end

  def protonbox_github_project_url(project)
    "https://github.com/protonbox/#{project}"
  end

  def mailto_protonbox_url
    'mailto:hi@protonbox.com'
  end

  def link_to_account_mailto
    link_to "hi@protonbox.com", mailto_protonbox_url
  end

  def status_jsonp_url(id)
    status_js_path :id => id
  end

  def open_issues_jsonp_url(jsonp)
    open_issues_js_path :jsonp => jsonp
  end
end
