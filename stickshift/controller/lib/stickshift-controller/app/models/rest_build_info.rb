
class RestBuildInfo < StickShift::Model
  attr_accessor :building_with, :building_app, :build_job_url

  def initialize(app)
    self.building_with = nil
    self.building_app = nil
    self.build_job_url = nil
    app.embedded.each { |cname, cinfo|
      cart = CartridgeCache::find_cartridge(cname)
      if cart.categories.include? "ci_builder"
        self.building_with = cart.name
        self.build_job_url = cinfo["job_url"]
        break
      end
    }
    app.user.applications.each { |user_app|
      cart = CartridgeCache::find_cartridge(user_app.framework)
      if cart.categories.include? "ci"
        self.building_app = user_app.name
        break
      end
    }
  end

  def to_xml(options={})
    options[:tag_name] = "build_info"
    super(options)
  end
end
