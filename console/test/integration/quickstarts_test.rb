require File.expand_path('../../test_helper', __FILE__)

class QuickstartsTest < ActiveSupport::TestCase

  test 'retrieve quickstarts' do
    quickstart = Quickstart.promoted.first
    omit('Quickstarts are not present on the server') if quickstart.nil?
    assert quickstart.tags.is_a? Array
    assert quickstart.tags.present?
    assert quickstart.tags.all?{ |t| t.is_a? Symbol }
    assert quickstart.name.present?
    assert quickstart.summary.present?
    if quickstart.body.present?
      assert quickstart.href.present?
      assert quickstart.updated > 1.year.ago
    end
  end

  test 'search quickstarts' do
    quickstarts = Quickstart.search('blog')
    omit('Quickstarts do not have a result matching "blog"') unless quickstarts.present?
    assert quickstarts.first.tags.include?(:blog)
  end
end
