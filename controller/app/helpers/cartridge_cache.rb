# Cache of cartridge manifest metadata. Used to reduce the number of calls 
# to the Node to retrieve cartridge information.
class CartridgeCache
  include CacheHelper

  # Returns an Array of Cartridge objects
  def self.cartridges
    CacheHelper.get_cached("all_cartridges", :expires_in => 21600.seconds) do
      carts = OpenShift::ApplicationContainerProxy.find_one().get_available_cartridges
      carts
    end
  end

  # Returns an Array of cartridge names.
  #
  # == Parameters:
  # cart_type::
  #   Specify to return only names of cartridges which have specified cartridge categories
  def self.cartridge_names(cart_type=nil, app=nil)
    if cart_type.nil?
      cartnames = CacheHelper.get_cached("cart_names_all", :expires_in => 1.day) { cartridges.map{ |cart| cart.name } }
      if app
        cartnames << app.downloaded_cartridges.values.keys.dup
        cartnames.flatten
      end
      return cartnames
    else
      cart_type = "web_framework" if cart_type == "standalone"
      find_cartridge_by_category(cart_type, app).map{ |cart| cart.name }
    end
  end

  def self.find_cartridge_by_category(cat, app=nil)
    global_carts = CacheHelper.get_cached("cartridges_by_cat_#{cat}", :expires_in => 1.day) {cartridges.select{|cart| cart.categories.include?(cat) }}
    if app
      app_local_community_carts = app.downloaded_cartridges.values.select { |cart| cart.categories.include?(cat) }
      global_carts << app_local_community_carts
      global_carts.flatten!
    end
    global_carts
  end

  # Returns the first cartridge that provides the specified feature.
  # @note This method matches both features provided by the cartridge as well as the cartridge name.
  #
  # == Parameters:
  # feature::
  #   Name of feature to look for.

  def self.find_cartridge(requested_feature, app=nil)

    app.downloaded_cartridges.values.each do |cart|
      return cart if cart.features.include?(requested_feature)
      return cart if cart.name == requested_feature
      return cart if cart.original_name == requested_feature
    end if app

    matching_carts = CacheHelper.get_cached("carts_by_feature_#{requested_feature}", :expires_in => 1.day) { self.find_all_cartridges(requested_feature) }

    return nil if matching_carts.empty?

    return matching_carts[0] if matching_carts.length == 1

    #if any is by redhat return that one
    cart = matching_carts.find { |c| c.cartridge_vendor == "redhat"}
    return cart if cart

    #if there are more than one match and none by redhat raise an exception
    choices = []
    matching_carts.each do |cart|
      choices << "#{cart.cartridge_vendor}-#{cart.name}-#{cart.version}"
    end

    raise OpenShift::UserException.new("More that one cartridge was found matching #{requested_feature}.  Please select one of #{choices.to_s}")

  end

  # Returns the first cartridge that provides the specified feature,
  # same as find_cartridge, but raise an OOException if no cartridge is
  # found.

  def self.find_cartridge_or_raise_exception(feature, app)
    find_cartridge(feature, app) or raise OpenShift::OOException.new("The application '#{app.name}' requires '#{feature}' but a matching cartridge could not be found")
  end

  def self.find_all_cartridges(requested_feature)

    carts = self.cartridges

    cartname_hash = {}
    cartname_version_hash = {}
    vendor_cartname_hash = {}
    vendor_cartname_version_hash = {}

    carts.each { |c|
      cartname = c.original_name
      cartname_hash[cartname] = [] if !cartname_hash[cartname]
      cartname_hash[cartname] << c

      cartname_version = c.original_name + "-" + c.version
      cartname_version_hash[cartname_version] = [] if !cartname_version_hash[cartname_version]
      cartname_version_hash[cartname_version] << c

      next if c.cartridge_vendor.to_s.empty?

      vendor_cartname = c.cartridge_vendor + "-" + c.original_name
      vendor_cartname_hash[vendor_cartname] = [] if !vendor_cartname_hash[vendor_cartname]
      vendor_cartname_hash[vendor_cartname] << c

      vendor_cartname_version = c.cartridge_vendor + "-" + c.original_name + "-" + c.version
      vendor_cartname_version_hash[vendor_cartname_version] = [] if !vendor_cartname_version_hash[vendor_cartname_version]
      vendor_cartname_version_hash[vendor_cartname_version] << c
    }

    return cartname_hash[requested_feature] if cartname_hash[requested_feature]
    return cartname_version_hash[requested_feature] if cartname_version_hash[requested_feature]
    return vendor_cartname_hash[requested_feature] if vendor_cartname_hash[requested_feature]
    return vendor_cartname_version_hash[requested_feature] if vendor_cartname_version_hash[requested_feature]

    matching_carts = []

    carts.each do |cart|
      matching_carts << cart if cart.features.include?(requested_feature) 
    end

    return matching_carts
  end


  def self.download_from_url(url)
    max_dl_time = (Rails.application.config.downloaded_cartridges[:max_download_time] rescue 10) || 10
    max_file_size = (Rails.application.config.downloaded_cartridges[:max_cart_size] rescue 20480) || 20480
    max_redirs = (Rails.application.config.downloaded_cartridges[:max_download_redirects] rescue 2) || 2
    rate_limit = (Rails.application.config.downloaded_cartridges[:max_download_rate] rescue "100k") || "100k" 
    manifest = ""

    uri_obj = URI.parse(url)
    if uri_obj.kind_of? URI::HTTP or uri_obj.kind_of? URI::FTP
      rout,wout = IO.pipe
      rerr,werr = IO.pipe
      pid = Process.spawn("curl", "-H", "X-OpenShift-Cartridge-Download:1", "--max-time", max_dl_time.to_s, "--limit-rate", rate_limit.to_s, "--connect-timeout", "2", "--location", "--max-redirs", max_redirs.to_s, "--max-filesize", max_file_size.to_s, "-k", url, :out => wout, :err => werr)
      begin
        Timeout::timeout(max_dl_time) {
          p,status = Process.waitpid2(pid)
          wout.close
          werr.close
          if status.exitstatus==0
            manifest = rout.read
          end
          rout.close
          rerr.close
        }
      rescue Timeout::Error
        Process.kill('SIGKILL', pid)
      end

      # manifest = `curl --max-time #{max_dl_time} --limit-rate #{rate_limit} --connect-timeout 2 --location --max-redirs #{max_redirs} --max-filesize #{max_file_size} -k #{url}`
    end
    manifest
  end

  def self.foreach_cart_version(manifest_str, software_version=nil)
    cartridge = OpenShift::Runtime::Manifest.new(manifest_str)
    cartridge.versions.each do |version|
      next if software_version and version!=software_version
      cooked = OpenShift::Runtime::Manifest.new(manifest_str, version)
      Rails.logger.debug("Loading #{cooked.name}-#{cooked.version}...")
      v1_manifest            = Marshal.load(Marshal.dump(cooked.manifest))
      # Appending the version to the cartridge name is being done in the common cartridge model 
      #v1_manifest['Name']    = "#{cooked.name}-#{cooked.version}"
      v1_manifest['Version'] = cooked.version
      vendored_name =  v1_manifest["Cartridge-Vendor"].to_s.empty? ? "#{cooked.name}-#{cooked.version}" : "#{cooked.cartridge_vendor}-#{cooked.name}-#{cooked.version}"
      yield v1_manifest,cooked.name,version,vendored_name
    end
  end

  def self.validate_yaml(url, str)
    raise OpenShift::UserException.new("Invalid cartridge, error downloading from url '#{url}' ", 109)  if str.nil? or str.length==0
    # raise OpenShift::UserException.new("Invalid manifest file from url '#{url}' - no structural directives allowed.") if str.include?("---")
    begin
      chash = OpenShift::Runtime::Manifest.manifest_from_yaml(str) 
      manifest = OpenShift::Runtime::Manifest.new(str)
    rescue Exception=>e
      raise OpenShift::UserException.new("Invalid manifest file from url '#{url}' - #{e.message}")
    end

    # check if Cartridge-Vendor is reserved
    begin
      manifest.check_reserved_vendor_name
    rescue OpenShift::InvalidElementError => iee
      # cloaking it as a UserException until Manifest starts raising subclasses of OOException 
      raise OpenShift::UserException.new(iee.message, 109)
    end

    chash
  end

  def self.fetch_community_carts(urls)
    cmap = {}
    return cmap if urls.nil?
    urls.each do |url|
       manifest_str = download_from_url(url)
       validate_yaml(url, manifest_str)

       # TODO: check versions and create multiple of them
       self.foreach_cart_version(manifest_str) do |chash,name,version,vendored_name|
         # do a trial parsing of the chash(v1 manifest) so that we do not store a manifest that will not get through elaborate later on
         cart = OpenShift::Cartridge.new.from_descriptor(chash)

         # all good, no exception above
         cmap[name] = { "versioned_name" => vendored_name, "url" => url, "original_manifest" => manifest_str, "version" => version}
         # no versioning support on downloaded cartridges yet.. use the default one
         break
       end
    end
    return cmap
  end

end
