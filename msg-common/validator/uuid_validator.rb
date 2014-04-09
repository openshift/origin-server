module MCollective
  module Validator
    class UuidValidator
      def self.validate(smth)
        Log.debug %Q(uuid(#{smth.class}) #{smth.inspect})

        Validator.typecheck(smth, :string)
        Validator.regex(smth, '^[a-fA-F0-9]+$')
        Validator.length(smth, 32)
      rescue ValidatorError => e
        raise ValidatorError, %Q(UUID is invalid, #{e.message})
      end
    end
  end
end
