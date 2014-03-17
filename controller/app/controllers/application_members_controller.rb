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
    
    def validate_role(role)
      return false unless Role.all.include? role.to_sym or role.to_sym == :none
      true
    end
    
    def validate_type(type)
      return false unless type == "user"
      true
    end
end