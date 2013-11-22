module DomainAssociations

  def self.when_belongs_to(klass, options)
    klass.class_eval do
      def self.prefix(p)
        check_prefix_options(p)
        p = HashWithIndifferentAccess.new(p)
        if p[:domain_id]
          retval = "#{RestApi::Base.prefix}domain/#{encode_path_component p[:domain_id]}/"
          # puts "Custom prefix of #{retval}"
        else
          retval = RestApi::Base.prefix
        end
        retval
      end

      def self.prefix_parameters
        [:domain_id]
      end

      def self.check_prefix_options(prefix_options)
        # No-op
      end

      def split_options(*args)
        (prefix_parameters, query_parameters) = super
        # puts "domain association split to \n\t#{prefix_parameters.inspect}\n\n\t#{query_parameters.inspect}"
        [prefix_parameters, query_parameters]
      end

      # domain_id overlaps with the attribute returned by the server
      def domain_id=(id)
        if self.prefix_options[:domain_id].nil?
          self.prefix_options[:domain_id] = id
        else
          super
        end
      end
      def domain_id
        super or self.prefix_options[:domain_id]
      end

      def domain
        Domain.find(domain_id, :params => {:include => :application_info}, :as => as) if domain_id
      end

      def domain=(domain)
        self.domain_id = if domain.kind_of?(Domain) 
            self.as = domain.as if self.as.nil?
            domain.id
          else
            domain
          end
      end
    end
  end

end
