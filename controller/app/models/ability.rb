#
# Abstracts all mapping of permissions to individual resources for OpenShift.  A
# permission is a specific action that a user can take - for most resources the 
# permission is granted either because of the role the user has on the resource,
# or due to a specific ownership relation.
#
# Roles are defined as being a set of strictly increasing permissions on a 
# particular resource - having a higher role entitles you to all permissions
# of the lower role.
#
# The permissions a user has at any time on a resource may be limited by the
# set of scopes they are operating under (used by authorization tokens) so that
# delegated authority can be granted.
#
module Ability

  #
  # Raise an exception unless the given actor has the specific permission on the resource.
  #
  def self.authorize!(actor_or_id, scopes, permission, resource, *resources)
    type = class_for_resource(resource) or raise OpenShift::OperationForbidden, "No actions are allowed"

    unless actor_or_id
      raise OpenShift::OperationForbidden, "You are not permitted to perform this action while not authenticated (#{permission} on #{type.to_s.underscore.humanize.downcase})"
    end

    if scopes.present? && !scopes.authorize_action?(permission, resource, actor_or_id, resources)
      raise OpenShift::OperationForbidden, "You are not permitted to perform this action with the scopes #{scopes} (#{permission} on #{type.to_s.underscore.humanize.downcase})"
    end

    role = resource.role_for(actor_or_id) if resource.respond_to?(:role_for)
    if has_permission?(actor_or_id, permission, type, role, resource, *resources) != true
      raise OpenShift::OperationForbidden, "You are not permitted to perform this action (#{permission} on #{type.to_s.underscore.humanize.downcase})"
    end

    true
  end

  #
  # Are any of the provided permissions available for the given actor_or_id on the specific resource or resources?
  #
  def self.authorized?(actor_or_id, scopes, permissions, resource, *resources)
    type = class_for_resource(resource) or return false
    return false unless actor_or_id
    permissions = Array(permissions)
    return false if scopes.nil? || !permissions.any?{ |p| scopes.authorize_action?(p, resource, resources, actor_or_id) }
    role = resource.role_for(actor_or_id) if resource.respond_to?(:role_for)
    permissions.any?{ |p| has_permission?(actor_or_id, p, type, role, resource) == true }
  end

  #
  # Does the active have a specific permission on a given resource.  Bypasses scope checking, so only use
  # when scopes are not relevant.
  #
  # NOTE: When adding new permissions, be sure to add those to the appropriate scopes as well.  By default
  #       all scopes will whitelist the allowed permissions, which means that new permissions are not
  #       automatically inherited.
  #
  def self.has_permission?(actor_or_id, permission, type, role, resource, *resources)
    if Application <= type
      case permission

      when :change_state,
           :change_cartridge_state,
           :make_ha,
           :scale_cartridge,
           :view_code_details,
           :change_gear_quota,
           :destroy,
           :create_cartridge,
           :destroy_cartridge,
           :create_alias,
           :update_alias,
           :ssh_to_gears,
           :destroy_alias,
           :view_environment_variables,
           :change_environment_variables,
           :update_application
        Role.in?(:edit, role)

      when :change_members,
           :leave
        false

      end

    elsif Domain <= type
      case permission
      when :create_application,
           :create_builder_application
        Role.in?(:edit, role)

      when :change_namespace
        Role.in?(:admin, role)

      when :change_members
        Role.in?(:admin, role)

      when :leave
        Role.in?(:view, role)

      when :change_gear_sizes, :destroy
        resource.owned_by?(actor_or_id)

      end

    elsif CloudUser <= type
      case permission
      when :create_key, :update_key, :destroy_key, :create_domain then resource === actor_or_id
      when :create_authorization, :update_authorization, :destroy_authorization then resource === actor_or_id
      when :change_plan then resource === actor_or_id
      when :destroy then resource.parent_user_id.present? && resource === actor_or_id
      end
    end
  end

  private
    def self.class_for_resource(resource)
      return resource if resource.is_a? Class
      resource.class
    end
end
