require File.expand_path('../../test_helper', __FILE__)

class ConfigTest < ActiveSupport::TestCase

  def parse_exp(*args)
    OpenShift::Controller::Configuration.send(:parse_expiration, *args)
  end

  test 'parse scope expirations' do
    assert_equal({nil => [1.seconds]},
                 parse_exp('', 1))
    assert_equal({nil => [1.days.seconds]},
                 parse_exp('* = 1.days', 1))
    assert_equal({nil => [1.days.seconds, 2.days.seconds]},
                 parse_exp('* = 1.days | 2.days', 1))
    assert_equal({nil => [1.seconds], 'session' => [1.days.seconds]},
                 parse_exp('session = 1.days', 1))
    assert_equal({nil => [1.seconds], 'session' => [1.days.seconds, 2.days.seconds]},
                 parse_exp('session = 1.days | 2.days', 1))
    assert_equal({nil => [1.seconds], 'a' => [1.days.seconds]},
                 parse_exp('a = 2, a = 1.days', 1))
  end

  def parse_urls(*args)
    OpenShift::Controller::Configuration.send(:parse_url_hash, *args)
  end

  test 'valid git url specs' do
    url="http://example.com/"
    assert_equal Hash.new, parse_urls(nil), "nil"
    assert_equal Hash.new, parse_urls(""), "literally empty"
    assert_equal Hash.new, parse_urls(" \t\n"), "space"
    assert_equal({ 'foo' => url }, parse_urls("foo|#{url}"), "single url")
    assert_equal({ 'foo' => "empty" }, parse_urls("foo|empty"), '"empty" URL (want empty git repo)')
    assert_equal url, parse_urls("bar|#{url}    foo|#{url}")['foo'], "two urls"
    assert_equal 3, parse_urls("bar|#{url} foo|#{url}\tbaz|empty").size, "three urls"
    assert_equal "#{url}#bar", parse_urls("foo|#{url}#bar")['foo'], "url with a commit hash #"
    assert_equal url, parse_urls("bar|file:///etc/openshift/bar    foo|#{url}")['foo'], "file: schema is ok"
  end

  test 'invalid git url specs' do
    assert_raise(RuntimeError, "no url") { parse_urls("foo") }
    assert_raise(RuntimeError, "no url 2") { parse_urls("foo bar|http://example.com/") }
    assert_raise(RuntimeError, "bad schema") { parse_urls("foo|bogus://example.com/") }
    assert_raise(RuntimeError, "bad schema") { parse_urls("foo|/etc/whatever/") }
  end

end
