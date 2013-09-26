require File.expand_path('../../test_helper', __FILE__)
require 'timeout'

class HelpLinkTest < ActionDispatch::IntegrationTest
  class << self
    def urls_from_module(mod)
      obj = Class.new { include Console::CommunityAware; include mod }.new

      mod.public_instance_methods.collect do |name|
        mod.instance_method(name)
      end.select do |m|
        m.name =~ /_url$/ && m.arity == 0
      end.inject({}) do |hash, m|
        uri = URI.parse(obj.send(m.name))
        hash["#{mod.name}##{m.name}"] = uri if uri.is_a?(URI::HTTPS) || uri.is_a?(URI::HTTP)
        hash
      end
    end
    def create_test(name, uri)
      test "can access #{name}(#{uri})" do
        check_url(name, uri)
      end
    end
  end

  def check_url(name, uri)
    begin
      req = Net::HTTP.new(uri.host, uri.port)
      if uri.is_a?(URI::HTTPS)
        req.use_ssl = true
        req.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      Timeout::timeout(2) do
        res = req.start do |http|
          http.get(uri.request_uri)
        end
        assert 200, res.code
      end
    rescue Timeout::Error 
      omit("Unable to reach #{uri} in under 2 seconds, skipping")
    rescue Exception => e
      raise e, "Could not retrieve #{name}(#{uri}): #{e.message}"
    end
  end

  urls_from_module(Console::HelpHelper).each_pair{ |name,uri| self.create_test(name,uri) }
  urls_from_module(Console::CommunityHelper).each_pair{ |name,uri| self.create_test(name,uri) }
end
