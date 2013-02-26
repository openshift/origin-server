class Scope::Userinfo < Scope::Simple
  description "Allows a client to view your login name, unique id, and your user capabilities."

  def allows_action?(controller)
    controller.is_a?(UserController) && controller.action_name == 'show'
  end
end
