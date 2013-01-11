module OpenShift
  class Cartridge < OpenShift::Model
    attr_accessor :name, :version, :architecture, :display_name, :description, :vendor, :license,
                  :provides, :requires, :conflicts, :suggests, :native_requires, :default_profile,
                  :path, :license_url, :categories, :website, :suggests_feature,
                  :help_topics, :cart_data_def
    attr_reader   :profiles
    
    def initialize
      super
      @_profile_map = {}
      @profiles = []      
    end
    
    def features
      features = self.provides.dup
      self.profiles.each do |profile|
        features += profile.provides
      end
      features.uniq
    end
    
    def profile_for_feature(feature)
      if feature.nil? || self.provides.include?(feature) || self.name == feature
        return @_profile_map[self.default_profile]
      else
        self.profiles.each do |profile|
          return profile if profile.provides.include? feature
        end
      end
    end
    
    def components_in_profile(profile)
      profile = self.default_profile if profile.nil?
      @_profile_map[profile].components
    end
    
    def has_component?(component_name)
      !get_component(component_name).nil?
    end
    
    def get_component(component_name)
      profiles.each{ |p| return p.get_component(component_name) unless p.get_component(component_name).nil? }
    end
    
    def get_profile_for_component(component_name)
      profiles.each{ |p| return p unless p.get_component(component_name).nil? }
    end
    
    def profiles=(p)
      @_profile_map = {}
      @profiles = p
      @profiles.each{ |profile| @_profile_map[p.name] = p }
    end
    
    def is_plugin?
      return categories.include?('web_proxy') || categories.include?('ci_builder') || categories.include?('plugin')
    end
    
    def is_service?
      return categories.include?('service')
    end

    def is_embeddable?
      return categories.include?('embedded')
    end
    
    def from_descriptor(spec_hash={})
      self.name = spec_hash["Name"]
      self.version = spec_hash["Version"] || "0.0"
      self.architecture = spec_hash["Architecture"] || "noarch"
      self.display_name = spec_hash["Display-Name"] || "#{self.name}-#{self.version}-#{self.architecture}"
      self.license = spec_hash["License"] || "unknown"
      self.license_url = spec_hash["License-Url"] || ""
      self.vendor = spec_hash["Vendor"] || "unknown"
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
      
      self.provides = [self.provides] if self.provides.class == String
      self.requires = [self.requires] if self.requires.class == String
      self.conflicts = [self.conflicts] if self.conflicts.class == String
      self.native_requires = [self.native_requires] if self.native_requires.class == String

      if spec_hash.has_key?("Profiles")
        spec_hash["Profiles"].each do |pname, p|
          profile = Profile.new.from_descriptor(self, p)
          profile.name = pname
          @profiles << (profile)
          @_profile_map[profile.name] = profile
        end
      else
        ["Name", "Version", "Architecture", "DisplayName", "License",
           "Provides", "Requires", "Conflicts", "Native-Requires"].each do |k|
          spec_hash.delete(k)
        end
        p = Profile.new.from_descriptor(self, spec_hash)
        p.name = self.name
        p.generated = true
        @profiles << p
        @_profile_map[p.name] = p
      end
      self.default_profile = spec_hash["Default-Profile"] || self.profiles.first.name
      self
    end
    
    def to_descriptor
      h = {
        "Name" => self.name,
        "Display-Name" => self.display_name,
      }
      
      h["Architecture"] = self.architecture if self.architecture != "noarch"
      h["Version"] = self.version if self.version != "0.0"
      h["Description"] = self.description if self.description and !self.description.empty?
      h["License"] = self.license if self.license and !self.license.empty? and self.license != "unknown"
      h["License-Url"] = self.license_url if self.license_url and !self.license_url.empty?
      h["Categories"] = self.categories if self.categories and !self.categories.empty?
      h["Website"] = self.website if self.website and !self.website.empty?
      h["Help-Topics"] = self.help_topics if self.help_topics and !self.help_topics.empty?
      h["Cart-Data"] = self.cart_data_def if self.cart_data_def and !self.cart_data_def.empty?

      h["Provides"] = self.provides if self.provides && !self.provides.empty?
      h["Requires"] = self.requires if self.requires && !self.requires.empty?
      h["Conflicts"] = self.conflicts if self.conflicts && !self.conflicts.empty?
      h["Suggests"] = self.suggests if self.suggests && !self.suggests.empty? 
      h["Native-Requires"] = self.native_requires if self.native_requires && !self.native_requires.empty?
      h["Vendor"] = self.vendor if self.vendor and !self.vendor.empty? and self.vendor != "unknown"
      h["Default-Profile"] = self.default_profile if !self.default_profile.nil? and !self.default_profile.empty? and !@_profile_map[@default_profile].generated
    
      if self.profiles.length == 1 && self.profiles.first.generated
        profile_h = self.profiles.first.to_descriptor
        profile_h.delete("Name")
        h.merge!(profile_h)
      else
        h["Profiles"] = {}
        self.profiles.each do |v|
          h["Profiles"][v.name] = v.to_descriptor
        end
      end
      
      h
    end
  end
end