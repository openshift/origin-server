class DomainMembersController < MembersController

  protected
    def membership
      @membership ||= get_domain
    end
end