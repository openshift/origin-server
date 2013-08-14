module Membership
  extend ActiveSupport::Concern

  included do
    has_many :members

    def members
      attributes[:members] || []
    end

    def owner?
      members.find{ |m| m.id == api_identity_id && m.owner? } if api_identity_id
    end

    def admin?
      has_role?('admin')
    end

    def editor?
      has_role?('admin','edit')
    end

    def readonly?
      has_role?('read')
    end

    def has_role?(*roles)
      roles.present? and api_identity_id.present? and members.find{ |m| m.id == api_identity_id && roles.include?(m.role) }
    end

  end
end
