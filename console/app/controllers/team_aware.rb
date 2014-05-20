module TeamAware
  extend ActiveSupport::Concern

  # trigger synchronous module load
  [Team, Member] if Rails.env.development?

  def user_teams(opts={})
    @user_teams ||= Team.find(:all, :params => {:include => "members"}, :as => current_user)
  end

  def user_owned_teams(opts={})
    @user_owned_teams ||= Team.find(:all, :params => {:include => "members", :owner => "@self"}, :as => current_user)
  end
end
