class ApplicationMembersController < MembersController
  protected
    def membership
      @membership ||= get_application
    end

    def save_membership(resource)
      resource.with_lock do 
        super
      end
    end

    def allowed_member_types
      ["user"]
    end
end