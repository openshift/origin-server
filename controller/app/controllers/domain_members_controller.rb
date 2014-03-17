class DomainMembersController < MembersController
    
  protected
    def membership
      @membership ||= get_domain
    end
    
    def validate_role(role)
      return false unless Role.all.include? role.to_sym or role.to_sym == :none
      true
    end
    
    def validate_type(type)
      return false unless type == "user" or type == "team"
      true
    end
end