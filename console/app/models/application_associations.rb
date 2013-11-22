module ApplicationAssociations

  def self.when_belongs_to(klass, options)
    klass.class_eval do
      schema do
        string :application_name
      end

      def self.prefix(p)
        check_prefix_options(p)
        p = HashWithIndifferentAccess.new(p)
        if p[:application_id]
          retval = "#{RestApi::Base.prefix}application/#{encode_path_component(Application.id_from_param(p[:application_id]))}/"
          # puts "Custom prefix of #{retval}"
        elsif p[:domain_id] and p[:application_name]
          retval = "#{RestApi::Base.prefix}domain/#{encode_path_component(p[:domain_id])}/application/#{encode_path_component(p[:application_name])}/"
          # puts "Custom prefix of #{retval}"
        else
          retval = RestApi::Base.prefix
        end
        retval
      end

      def self.prefix_parameters
        [:domain_id, :application_name, :application_id]
      end

      def self.check_prefix_options(prefix_options)
        p = HashWithIndifferentAccess.new(prefix_options)
        return if p[:domain_id] and p[:application_name]
        return if p[:application_id]
        raise(ActiveResource::MissingPrefixParam, ":domain_id/:application_name or :application_id prefix_option is missing")
      end

      def split_options(*args)
        (prefix_parameters, query_parameters) = super
        if prefix_parameters and prefix_parameters[:application_id]
          old = prefix_parameters[:application_id]
          prefix_parameters[:application_id] = Application.id_from_param(prefix_parameters[:application_id])
          puts "Changed #{old} to #{prefix_parameters[:application_id]}" if old != prefix_parameters[:application_id]
        end
        [prefix_parameters, query_parameters]
      end

      def application_id=(id)
        if self.prefix_options[:application_id].nil?
          self.prefix_options[:application_id] = id
        else
          super rescue nil
        end
      end
      def application_id
        (super rescue nil) or self.prefix_options[:application_id]
      end

      def application_name=(name)
        if self.prefix_options[:application_name].nil?
          self.prefix_options[:application_name] = name
        else
          super
        end
      end
      def application_name
        (super rescue nil) or self.prefix_options[:application_name]
      end
      def domain_id=(id)
        self.prefix_options[:domain_id] = id
      end
      def domain_id
        (super rescue nil) or self.prefix_options[:domain_id]
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
