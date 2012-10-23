module DomainAssociations

  def self.when_belongs_to(klass, options)
    klass.prefix = "#{RestApi::Base.prefix}domains/:domain_id/"
    klass.class_eval do
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
        Domain.find(domain_id, :as => as)
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
