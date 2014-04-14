require_relative '../test_helper'

class CloudUserTest < ActiveSupport::TestCase

  def setup
    stubber
  end

  def test_force_delete
    random = rand(1000000000)
    login = "user#{@random}"
    password = "password"
    user = CloudUser.new(login: login)
    user.save!
    Lock.create_lock(user.id)

    team_name = "team#{random}"
    team = Team.create(name: team_name, owner_id:user._id)
    assert_equal Team.where(owner_id: user._id).count, 1
    namespace = "ns#{random}"
    domain = Domain.create!(namespace: namespace, owner: user)
    assert_equal Domain.where(owner_id: user._id).count, 1
    assert user.force_delete
    assert_equal Team.where(owner_id: user._id).count, 0
    assert_equal Domain.where(owner_id: user._id).count, 0
  end

end