module SecuredHelper
  def logged_in?
    controller.logged_in?
  end

  def logged_in_id
    controller.current_user.login if controller.logged_in?
  end

  def previously_logged_in?
    controller.previously_logged_in?
  end
end
