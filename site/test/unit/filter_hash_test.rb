require File.expand_path('../../test_helper', __FILE__)

require 'filter_hash'

class FilterHashTest < ActiveSupport::TestCase

  F = '[FILTERED]'

  def test_filters
    assert_equal ['password'], FilterHash.send(:filters)
  end

  def test_filter_defaults
    keys = [:password, 'password', 'Password', 'old_password', 'password_confirmation']
    assert_equal filtered_hash(keys), FilterHash.safe_values(valid_hash(keys))
  end

  def test_filters_are_cached
    FilterHash.instance_variable_set(:@filters, nil)
    FilterHash.safe_values({})
    assert first = FilterHash.instance_variable_get(:@filters)
    FilterHash.safe_values({})
    assert_equal first, FilterHash.instance_variable_get(:@filters)

  end


  def test_filter_case_partials
    FilterHash.expects(:filters).returns(['case'])
    keys = [:case, 'Case', 'cAse', 'lowerCase', 'lowercase']
    assert_equal filtered_hash(keys), FilterHash.safe_values(valid_hash(keys))
  end

  def test_filter_case_nomatch
    FilterHash.expects(:filters).returns(['case'])
    keys = [:cas, 'cas', 'Cas', 'caS', 'ase']
    assert_equal valid_hash(keys), FilterHash.safe_values(valid_hash(keys))
  end

  def test_filter_case_multiple
    FilterHash.expects(:filters).returns(['password', 'other'])
    keys = [:password, :passWord, :other, :otheR, 'other', 'password', 'Password', 'oTher']
    assert_equal filtered_hash(keys), FilterHash.safe_values(valid_hash(keys))
  end

  def test_filter_case_multiple_nomatch
    FilterHash.expects(:filters).returns(['foo', 'bar'])
    keys = [:password, :passWord, :other, :otheR, 'other', 'password', 'Password', 'oTher']
    assert_equal valid_hash(keys), FilterHash.safe_values(valid_hash(keys))
  end

  def valid_hash(*args)
    h = {}
    args.each{ |k| h[k] = 'test' }
    h
  end
  def filtered_hash(*args)
    h = {}
    args.each{ |k| h[k] = F }
    h
  end

  def assert_filtered(hash, *args)
    args.each{ |k| assert_equal '[FILTERED]', hash[k], "Key #{k} was not filtered" }
  end
end
