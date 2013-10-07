class Scope::Read < Scope::Simple
  description "Allows the client to access resources you own without making changes. Does not allow access to view authorization tokens."

  def allows_action?(controller)
    controller.request.method == "GET" && !controller.is_a?(AuthorizationsController)
  end

  def limits_access(criteria)
    criteria.options[:visible] ||= !(Authorization === criteria.klass)
    criteria
  end
end
