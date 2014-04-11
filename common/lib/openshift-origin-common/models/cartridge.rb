module OpenShift
  module CartridgeCategories
    def is_plugin?
      is_web_proxy? || is_ci_builder? || categories.include?('plugin')
    end

    def is_service?
      categories.include?('service')
    end

    def is_external?
      categories.include?('external')
    end

    def is_embeddable?
      categories.include?('embedded')
    end

    def is_domain_scoped?
      categories.include?('domain_scope')
    end

    def is_web_proxy?
      categories.include?('web_proxy')
    end

    def is_web_framework?
      categories.include?('web_framework')
    end

    def is_ci_server?
      categories.include?('ci')
    end

    def is_ci_builder?
      categories.include?('ci_builder')
    end

    def has_scalable_categories?
      is_web_framework? || is_service?
    end

    alias_method :is_deployable?, :is_web_framework?
    alias_method :is_buildable?, :is_web_framework?
  end


  module CartridgeAspects
    def is_premium?
      usage_rates.present?
    end

    def usage_rates
      []
    end
  end

  #
  # The including class must define original_name, cartridge_vendor, and version
  #
  module CartridgeNaming
    def names
      @names ||= [short_name, full_name, prefix_name, original_name]
    end

    def full_identifier
      if cartridge_vendor.nil? || cartridge_vendor.empty?
        short_name
      else
        full_name
      end
    end

    def global_identifier
      if self.cartridge_vendor == "redhat" || self.cartridge_vendor.to_s.empty?
        short_name
      else
        full_name
      end
    end

    protected
      def full_name
        "#{cartridge_vendor}-#{original_name}-#{version}"
      end
      def short_name
        "#{original_name}-#{version}"
      end
      def prefix_name
        "#{cartridge_vendor}-#{original_name}"
      end
  end

  class Cartridge < OpenShift::Model
    # General cartridge metadata
    attr_accessor :id, :name, :version, :architecture, :display_name, :description, :vendor, :license,
                  :provides, :requires, :conflicts, :suggests, :native_requires,
                  :path, :license_url, :categories, :website, :suggests_feature,
                  :help_topics, :cart_data_def, :additional_control_actions, :versions, :cartridge_vendor,
                  :endpoints, :cartridge_version, :obsolete, :platform

    # Profile information
    attr_accessor :components, :group_overrides, :connections, :configure_order

    # Available for downloadable cartridges
    attr_accessor :manifest_text, :manifest_url

    # Available in certain contexts
    attr_accessor :created_at, :activated_at

    include CartridgeCategories
    include CartridgeAspects
    include CartridgeNaming

    VERSION_ORDER = lambda{ |s| s.version.split('.').map(&:to_i) rescue [0] }
    NAME_PRECEDENCE_ORDER = lambda{ |c| [c.original_name, c.cartridge_vendor == "redhat" ? 0 : 1, *(c.version.split('.').map{ |i| -i.to_i } rescue [0])] }

    def initialize(descriptor=nil, singleton=false)
      super()
      @singleton = singleton
      @endpoints = []
      @_component_name_map = {}
      @components = []
      @connections = []
      @group_overrides = []
      from_descriptor(descriptor) if descriptor
    end

    def categories
      @categories ||= []
    end

    def features
      @features ||= begin
        features = self.provides.dup
        features.uniq!
        features
      end
    end

    def has_feature?(feature)
      names.include?(feature) || features.include?(feature)
    end

    def has_component?(component_name)
      !get_component(component_name).nil?
    end

    def components=(data)
      @components = data
      @components.each {|comp| @_component_name_map[comp.name] = comp }
    end

    def scaling_required?
      @components.any? { |comp| comp.scaling.required }
    end

    def get_component(comp_name)
      @_component_name_map[comp_name]
    end

    def is_obsolete?
      obsolete || false
    end

    def from_descriptor(spec_hash={})
      self.id = spec_hash["Id"]
      self.name = spec_hash["Name"]
      self.version = spec_hash["Version"] || "0.0"
      self.versions = spec_hash["Versions"] || []
      self.architecture = spec_hash["Architecture"] || "noarch"
      self.display_name = spec_hash["Display-Name"] || "#{self.original_name}-#{self.version}-#{self.architecture}"
      self.license = spec_hash["License"] || "unknown"
      self.license_url = spec_hash["License-Url"] || ""
      self.vendor = spec_hash["Vendor"] || "unknown"
      self.cartridge_vendor = spec_hash["Cartridge-Vendor"] || "unknown"
      self.description = spec_hash["Description"] || ""
      self.provides = spec_hash["Provides"] || []
      self.requires = spec_hash["Requires"] || []
      self.conflicts = spec_hash["Conflicts"] || []
      self.native_requires = spec_hash["Native-Requires"] || []
      self.categories = spec_hash["Categories"] || []
      self.website = spec_hash["Website"] || ""
      self.suggests = spec_hash["Suggests"] || []
      self.help_topics = spec_hash["Help-Topics"] || {}
      self.cart_data_def = spec_hash["Cart-Data"] || {}
      self.additional_control_actions = spec_hash["Additional-Control-Actions"] || []
      self.cartridge_version = spec_hash["Cartridge-Version"] || "0.0.0"
      self.platform = (spec_hash["Platform"] || "linux").downcase

      self.provides = [self.provides] if self.provides.class == String
      self.requires = [self.requires] if self.requires.class == String
      self.conflicts = [self.conflicts] if self.conflicts.class == String
      self.native_requires = [self.native_requires] if self.native_requires.class == String

      self.endpoints = []
      if (endpoints = spec_hash["Endpoints"]).respond_to?(:each)
        endpoints.each do |ep|
          self.endpoints << Endpoint.new.from_descriptor(ep)
        end
      end

      self.configure_order = spec_hash["Configure-Order"] || []

      #fixup user data. provides, configure_order must be arrays
      self.provides = [self.provides] if self.provides.class == String
      self.configure_order = [self.configure_order] if self.configure_order.class == String

      if (components = spec_hash["Components"]).is_a? Hash
        components.each do |cname, c|
          comp = Component.new.from_descriptor(self, c || {})
          comp.name = cname
          @components << comp
          @_component_name_map[comp.name] = comp
        end
      else
        c = Component.new.from_descriptor(self, {
          "Publishes"  => spec_hash["Publishes"],
          "Subscribes" => spec_hash["Subscribes"],
          "Scaling"    => spec_hash["Scaling"],
        })
        c.generated = true
        @components << c
        @_component_name_map[c.name] = c
      end

      if (connections = spec_hash["Connections"]).is_a? Hash
        connections.each{ |n,c| self.connections << Connection.new(n).from_descriptor(c) }
      end

      self.group_overrides ||= []
      if (overrides = spec_hash["Group-Overrides"]).is_a? Array
        overrides.each{ |o| self.group_overrides << o.dup }
      end

      self.obsolete = spec_hash["Obsolete"] || false
      self
    end

    alias_method :name, :global_identifier

    def original_name
      @name
    end

    def ===(other)
      return true if other == self
      if other.is_a?(String)
        if cartridge_vendor == "redhat"
          name == other || full_name == other
        else
          name == other
        end
      end
    end

    def to_descriptor
      h = {
        "Name" => self.original_name,
        "Display-Name" => self.display_name,
      }

      h["Id"] = self.id if self.id
      h["Architecture"] = self.architecture if self.architecture != "noarch"
      h["Version"] = self.version if self.version != "0.0"
      h["Versions"] = self.versions if self.versions and !versions.empty?
      h["Description"] = self.description if self.description and !self.description.empty?
      h["License"] = self.license if self.license and !self.license.empty? and self.license != "unknown"
      h["License-Url"] = self.license_url if self.license_url and !self.license_url.empty?
      h["Categories"] = self.categories if self.categories and !self.categories.empty?
      h["Website"] = self.website if self.website and !self.website.empty?
      h["Help-Topics"] = self.help_topics if self.help_topics and !self.help_topics.empty?
      h["Cart-Data"] = self.cart_data_def if self.cart_data_def and !self.cart_data_def.empty?
      h["Additional-Control-Actions"] = self.additional_control_actions if self.additional_control_actions and !self.additional_control_actions.empty?
      h["Cartridge-Version"] = self.cartridge_version if self.cartridge_version != "0.0.0"

      h["Provides"] = self.provides if self.provides && !self.provides.empty?
      h["Requires"] = self.requires if self.requires && !self.requires.empty?
      h["Conflicts"] = self.conflicts if self.conflicts && !self.conflicts.empty?
      h["Suggests"] = self.suggests if self.suggests && !self.suggests.empty?
      h["Native-Requires"] = self.native_requires if self.native_requires && !self.native_requires.empty?
      h["Vendor"] = self.vendor if self.vendor and !self.vendor.empty? and self.vendor != "unknown"
      h["Cartridge-Vendor"] = self.cartridge_vendor if self.cartridge_vendor and !self.cartridge_vendor.empty? and self.cartridge_vendor != "unknown"
      h["Obsolete"] = self.obsolete if !self.obsolete.nil? and self.obsolete
      h["Platform"] = self.platform if !self.platform.nil? and self.platform

      if self.endpoints.present?
        h["Endpoints"] = self.endpoints.map(&:to_descriptor)
      end

      h["Configure-Order"] = @configure_order unless @configure_order.nil? || @configure_order.empty?

      if self.components.length == 1 && self.components.first.generated
        comp_h = self.components.first.to_descriptor
        comp_h.delete("Name")
        h.merge!(comp_h)
      else
        h["Components"] = {}
        self.components.each do |v|
          h["Components"][v.name] = v.to_descriptor
        end
      end

      if self.connections.present?
        h["Connections"] = {}
        self.connections.each do |v|
          h["Connections"][v.name] = v.to_descriptor
        end
      end

      if self.group_overrides.present?
        h["Group-Overrides"] = self.group_overrides
      end

      h
    end

    def specification_hash
      h = {
        'name' => name,
        'id' => id,
      }
      h['manifest_url'] = manifest_url if manifest_url
      h['manifest_text'] = manifest_text if manifest_text
      h
    end

    def singleton?
      @singleton
    end
  end
end
