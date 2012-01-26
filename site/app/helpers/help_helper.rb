module HelpHelper

  # Given a relative path within the user guide, display the topic
  def user_guide_topic_url(topic)
    locale = 'en-US'
    "http://docs.redhat.com/docs/#{locale}/OpenShift_Express/2.0/html/User_Guide/#{topic}"
  end
end
