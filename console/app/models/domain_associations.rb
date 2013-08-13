module DomainAssociations

  def self.when_belongs_to(klass, options)
    klass.class_eval do

      def self.prefix(p)
        p = {} unless p
        if p[:domain_id]
          retval = "#{RestApi::Base.prefix}domain/#{p[:domain_id]}/"
          puts "Custom prefix of #{retval}"
        else
          retval = RestApi::Base.prefix
        end
        retval
      end

      def self.adjust_parameters(prefix_parameters, query_parameters)
        puts "Turning #{prefix_parameters.inspect}, #{query_parameters.inspect}"
        prefix_parameters.merge!(query_parameters.slice(:domain_id))
        query_parameters.delete(:domain_id)
        puts "\t into #{prefix_parameters.inspect}, #{query_parameters.inspect}"
      end

      def self.element_path(id, prefix_parameters={}, query_parameters=nil)
        prefix_parameters={} unless prefix_parameters
        query_parameters={} unless query_parameters
        adjust_parameters(prefix_parameters, query_parameters)
        super(id, prefix_parameters, query_parameters)
      end

      def self.collection_path(prefix_parameters={}, query_parameters={})
        prefix_parameters={} unless prefix_parameters
        query_parameters={} unless query_parameters
        adjust_parameters(prefix_parameters, query_parameters)
        super(prefix_parameters, query_parameters)
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
        Domain.find(domain_id, :as => as) if domain_id
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
