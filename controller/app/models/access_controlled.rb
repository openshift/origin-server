#
# A model with the ability to add and remove membership.  Membership changes may require
# work to be done on distributed resources associated with this model, or on child resources.
#
module AccessControlled
  extend ActiveSupport::Concern

  module ClassMethods
    def accessible(to)
      scope_limited(to)
    end

    def scope_limited(to, criteria=queryable)
      if to.respond_to?(:scopes) && (scopes = to.scopes)
        criteria = scopes.limit_access(criteria)
      end
      criteria
    end
  end

  def owned_by?(actor_or_id)
    id = actor_or_id.respond_to?(:_id) ? actor_or_id._id : actor_or_id
    self.owner_id == id
  end
end
