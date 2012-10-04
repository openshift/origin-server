module OpenShift
  class Cartridge < OpenShift::UserModel
    attr_accessor :name, :version, :architecture, :display_name, :description, :vendor, :license,
                  :provides_feature, :requires_feature, :conflicts_feature, :requires, :default_profile,
                  :path, :profile_name_map, :license_url, :categories, :website, :suggests_feature,
                  :help_topics, :cart_data_def
    exclude_attributes :profile_name_map
    include_attributes :profiles
    
    def initialize
      super
      self.from_descriptor({"Name" => "unknown-cartridge"})
      self.profile_name_map = {}
    end
    
    def all_capabilities
      caps = self.provides_feature.dup
      self.profiles.each do |v|
        caps += v.provides
      end
      caps.uniq
    end
    
    def profiles=(data)
      data.each do |value|
        add_profile(value)
      end
    end
    
    def profiles(name=nil)
      @profile_name_map = {} if @profile_name_map.nil?
      if name.nil?
        @profile_name_map.values
      else
        @profile_name_map[name]
      end
    end
    
    def add_profile(profile)
      profile_name_map_will_change!
      profiles_will_change!
      @profile_name_map = {} if @profile_name_map.nil?
      if profile.class == Profile
        @profile_name_map[profile.name] = profile
      else        
        key = profile["name"]            
        @profile_name_map[key] = Profile.new
        @profile_name_map[key].attributes=profile
      end
    end
    
    # Search for a profile that provides specified capabilities
    def find_profile(capability)
      if capability.nil? || self.provides_feature.include?(capability)
        return @profile_name_map[self.default_profile]
      end
      
      self.profiles.each do |p|
        return p if p.provides.include? capability
      end
      nil
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
      self.provides_feature = spec_hash["Provides"] || []
      self.requires_feature = spec_hash["Requires"] || []
      self.conflicts_feature = spec_hash["Conflicts"] || []
      self.requires = spec_hash["Native-Requires"] || []
      self.categories = spec_hash["Categories"] || ["cartridge"]
      self.website = spec_hash["Website"] || ""
      self.suggests_feature = spec_hash["Suggests"] || []
      self.help_topics = spec_hash["Help-Topics"] || {}
      self.cart_data_def = spec_hash["Cart-Data"] || {}
      
      self.provides_feature = [self.provides_feature] if self.provides_feature.class == String
      self.requires_feature = [self.requires_feature] if self.requires_feature.class == String
      self.conflicts_feature = [self.conflicts_feature] if self.conflicts_feature.class == String
      self.requires = [self.requires] if self.requires.class == String

      if spec_hash.has_key?("Profiles")
        spec_hash["Profiles"].each do |pname, p|
          profile = Profile.new.from_descriptor(p)
          profile.name = pname
          add_profile(profile)
        end
      else
        ["Name", "Version", "Architecture", "DisplayName", "License",
           "Provides", "Requires", "Conflicts", "Native-Requires"].each do |k|
          spec_hash.delete(k)
        end
        p = Profile.new.from_descriptor(spec_hash)
        p.name = "default"
        p.generated = true
        add_profile(p)
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

      h["Provides"] = self.provides_feature if self.provides_feature && !self.provides_feature.empty?
      h["Requires"] = self.requires_feature if self.requires_feature && !self.requires_feature.empty?
      h["Conflicts"] = self.conflicts_feature if self.conflicts_feature && !self.conflicts_feature.empty?
      h["Suggests"] = self.suggests_feature if self.suggests_feature && !self.suggests_feature.empty? 
      h["Native-Requires"] = self.requires if self.requires && !self.requires.empty?
      h["Vendor"] = self.vendor if self.vendor and !self.vendor.empty? and self.vendor != "unknown"
      h["Default-Profile"] = self.default_profile if self.profile_name_map && !self.profile_name_map[self.default_profile].nil? &&
                                                      !self.profile_name_map[self.default_profile].generated
    
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
    
    def get_name_prefix
      return "/cart-" + self.name
    end
  end
end
