module StickShift
  class Cartridge < StickShift::UserModel
    attr_accessor :name, :version, :architecture, :display_name, :description, :vendor, :license,
                  :provides_feature, :requires_feature, :conflicts_feature, :requires, :default_profile,
                  :path, :profile_name_map
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
      self.vendor = spec_hash["Vendor"] || "unknown"
      self.description = spec_hash["Description"] || ""
      self.provides_feature = spec_hash["Provides"] || []
      self.requires_feature = spec_hash["Requires"] || []
      self.conflicts_feature = spec_hash["Conflicts"] || []
      self.requires = spec_hash["Native-Requires"] || []
      
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
        "Version" => self.version,
        "Architecture" => self.architecture,
        "Display-Name" => self.display_name,
        "Description" => self.description        
      }
      
      h["License"] = self.license if self.license
      h["Provides"] = self.provides_feature if self.provides_feature && !self.provides_feature.empty?
      h["Requires"] = self.requires_feature if self.requires_feature && !self.requires_feature.empty?
      h["Conflicts"] = self.conflicts_feature if self.conflicts_feature && !self.conflicts_feature.empty?
      h["Native-Requires"] = self.requires if self.requires && !self.requires.empty?
      h["Vendor"] = self.vendor if self.vendor
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
