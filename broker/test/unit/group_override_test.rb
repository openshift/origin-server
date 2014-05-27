ENV["TEST_NAME"] = "unit_group_override"
require_relative '../test_helper'

class GroupOverrideTest < ActiveSupport::TestCase
  test "remove empty specs" do
    assert_equal [], GroupOverride.reduce([
      nil,
      GroupOverride.new([]),
    ])
  end

  test "reduce duplicates" do
    assert_equal [
      GroupOverride.new([ComponentSpec.new('a', 'a')], 1)
    ], GroupOverride.reduce([
      GroupOverride.new([ComponentSpec.new('a', 'a')], 1),
      GroupOverride.new([ComponentSpec.new('a', 'a')]),
    ])
  end

  test "merge groups" do
    assert_equal [
      GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('b', 'b')], 2)
    ], GroupOverride.reduce([
      GroupOverride.new([ComponentSpec.new('a', 'a')], 2),
      GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('b', 'b')], 1),
    ])
  end

  test "implicit override remains implicit" do
    r = GroupOverride.reduce([
      GroupOverride.new([ComponentSpec.new('a', 'a')], 2).implicit,
      GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('b', 'b')], 1).implicit,
      GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('b', 'b')], 1),
    ])
    assert_equal [GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('b', 'b')], 2)], r
    assert r[0].implicit?
  end

  test "more specific override clears implicit" do
    r = GroupOverride.reduce([
      GroupOverride.new([ComponentSpec.new('a', 'a')], 2).implicit,
      GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('b', 'b')], 1).implicit,
      GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('b', 'b')], 3),
    ])
    assert_equal [GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('b', 'b')], 3)], r
    assert !r[0].implicit?
  end

  test "merge separate groups" do
    assert_equal [
      GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('b', 'b')], 3)
    ], GroupOverride.reduce([
      GroupOverride.new([ComponentSpec.new('b', 'b')], 3),
      GroupOverride.new([ComponentSpec.new('a', 'a')], 2),
      GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('b', 'b')], 1),
    ])
  end

  test "merge disjoint groups" do
    assert_equal [
      GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('b', 'b'), ComponentSpec.new('c', 'c')], 2)
    ], GroupOverride.reduce([
      GroupOverride.new([ComponentSpec.new('a', 'a')], 2),
      GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('b', 'b')], 1),
      GroupOverride.new([ComponentSpec.new('c', 'c')], 1),
      GroupOverride.new([ComponentSpec.new('b', 'b'), ComponentSpec.new('c', 'c')]),
    ])
  end

  test "merge more disjoint groups" do
    assert_equal [
      GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('b', 'b'), ComponentSpec.new('c', 'c')], 2)
    ], GroupOverride.reduce([
      GroupOverride.new([ComponentSpec.new('a', 'a')], 2),
      GroupOverride.new([ComponentSpec.new('b', 'b'), ComponentSpec.new('c', 'c')]),
      GroupOverride.new([ComponentSpec.new('a', 'a'), ComponentSpec.new('c', 'c')], 1),
    ])
  end

  test "merge preserves correct precedence" do
    assert_equal GroupOverride.new(nil, 2, 10, 'small', 1), GroupOverride.new(nil, 2, -1, 'small', 0).merge(GroupOverride.new(nil, 1, 10, nil, 1))
    assert_equal GroupOverride.new(nil, 2, 10, 'small', 1), GroupOverride.new(nil, 1, 10, nil, 1).merge(GroupOverride.new(nil, 2, -1, 'small', 0))

    assert_equal GroupOverride.new([ComponentSpec.new('a','a'), ComponentSpec.new('b','b')]), 
                 GroupOverride.new([ComponentSpec.new('a','a')]).merge(GroupOverride.new([ComponentSpec.new('b','b')]))
  end

  test "merge preserves component overrides" do
    assert_equal GroupOverride.new([ComponentOverrideSpec.new(ComponentSpec.new('a','a'), 1, 1, 1)]), 
                 GroupOverride.new([ComponentSpec.new('a','a')]).merge(GroupOverride.new([ComponentOverrideSpec.new(ComponentSpec.new('a','a'), 1, 1, 1)]))
    assert_equal GroupOverride.new([ComponentOverrideSpec.new(ComponentSpec.new('a','a'), 2, 10, 1)]), 
                 GroupOverride.new([ComponentOverrideSpec.new(ComponentSpec.new('a','a'), 1, -1, 0)]).merge(GroupOverride.new([ComponentOverrideSpec.new(ComponentSpec.new('a','a'), 2, 10, 1)]))
  end

  test "merge resets component override implicit" do
    implicit = GroupOverride.new([ComponentSpec.new('b','b'), ComponentSpec.new('a','a')]).implicit
    merged = implicit.merge(GroupOverride.new([ComponentSpec.new('b','b'), ComponentOverrideSpec.new(ComponentSpec.new('a','a'), 2, -1, 2)]))
    assert_equal GroupOverride.new([ComponentSpec.new('b','b'), ComponentOverrideSpec.new(ComponentSpec.new('a','a'), 2, -1, 2)]), merged
    assert !merged.implicit?
  end
end