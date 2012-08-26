module SecuredHelper
  def current_user_id
    controller.current_user.login if controller.user_signed_in?
  end
end
