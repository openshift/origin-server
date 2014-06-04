class ApplicationMembersController < MembersController
  protected
    def membership
      @membership ||= get_application
    end

    def save_membership(resource)
      # Save before locking, since locking can reload
      if resource.save
        resource.with_lock do 
          resource.run_jobs
        end
        true
      end
    end

end