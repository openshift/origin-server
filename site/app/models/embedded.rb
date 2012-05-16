class Embedded < RestApi::Base
  def info(cart)
    @attributes[cart].info rescue nil
  end

  #FIXME: Bug 820651 should make this cleaner to retrieve
  def jenkins_build_url
    client = info('jenkins-client-1.4')
    ((client || '').chomp)[/Job URL: ([^\s]*)\s*/, 1]
  end
end
