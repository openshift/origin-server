module ApplicationAssociations

  def self.when_belongs_to(klass, options)
    klass.class_eval do
      schema do
        string :application_name
      end

      def self.prefix(p)
        p = {} unless p
        if p[:application_id]
          retval = "#{RestApi::Base.prefix}application/#{p[:application_id]}/"
          puts "Custom prefix of #{retval}"
        elsif p[:domain_id] and p[:application_name]
          retval = "#{RestApi::Base.prefix}domain/#{v[:domain_id]}/application/#{v[:application_name]}/"
          puts "Custom prefix of #{retval}"
        else
          retval = RestApi::Base.prefix
        end
        retval
      end

      def self.adjust_parameters(prefix_parameters, query_parameters)
        puts "Turning #{prefix_parameters.inspect}, #{query_parameters.inspect}"
        params = [:application_id, :application_name, :domain_id]
        prefix_parameters.merge!(query_parameters.slice(*params))
        query_parameters.delete_if {|k| params.include?(k) }
        prefix_parameters[:application_id] = Application.id_from_param(prefix_parameters[:application_id]) if prefix_parameters[:application_id]
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

      def application_id=(id)
        if self.prefix_options[:application_id].nil?
          self.prefix_options[:application_id] = id
        else
          super
        end
      end
      def application_id
        super or self.prefix_options[:application_id]
      end

      def application_name=(name)
        if self.prefix_options[:application_name].nil?
          self.prefix_options[:application_name] = name
        else
          super
        end
      end
      def application_name
        super or self.prefix_options[:application_name]
      end
      def domain_id=(id)
        self.prefix_options[:domain_id] = id
      end
      def domain_id
        super or self.prefix_options[:domain_id]
      end
      def application
        if application_id.present?
          Application.find application_id, :as => as
        elsif application_name.present? and domain_id.present?
          Application.find application_name, :params => {:domain_id => domain_id}, :as => as
        end
      end
      def application=(application)
        self.application_id = application.id
        self.application_name = application.name
        self.domain_id = application.domain_id
        self.as = application.as if self.as.nil?
      end
    end
  end

end
