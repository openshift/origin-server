module ApplicationAssociations

  def self.when_belongs_to(klass, options)
    klass.prefix = "#{RestApi::Base.prefix}domains/:domain_id/applications/:application_name/"
    klass.class_eval do
      schema do
        string :application_name
      end
      def application_name=(id)
        if self.prefix_options[:application_name].nil?
          self.prefix_options[:application_name] = id
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
        self.prefix_options[:domain_id]
      end
      def application
        Application.find application_name, :params => {:domain_id => domain_id}, :as => as
      end
      def application=(application)
        self.application_name = application.name
        self.domain_id = application.domain_id
        self.as = application.as if self.as.nil?
      end
    end
  end

end
