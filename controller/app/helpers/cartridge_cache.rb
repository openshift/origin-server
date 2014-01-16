# Cache of cartridge manifest metadata. Used to reduce the number of calls
# to the Node to retrieve cartridge information.

require 'httpclient'

class CartridgeCache

  DURATION = 6.hours

  # Returns an Array of Cartridge objects
  def self.cartridges(show_obsolete=nil)
    show_obsolete = show_obsolete || Rails.configuration.openshift[:allow_obsolete_cartridges]
    get_all_cartridges.select{ |cart| show_obsolete || !cart.is_obsolete? }
  end

  # Returns an Array of cartridge names.
  #
  # == Parameters:
  # cart_type::
  #   Specify to return only names of cartridges which have specified cartridge categories
  def self.cartridge_names(type=nil, app=nil)
    if type.nil?
      names = Rails.cache.fetch("cart_names_all", :expires_in => DURATION){ cartridges.map(&:name) }
      names.concat(app.downloaded_cartridge_instances.keys) if app
      names
    else
      type = "web_framework" if type == "standalone"
      find_cartridge_by_category(type, app).map(&:name)
    end
  end

  def self.find_cartridge_by_category(category, app=nil)
    carts = Rails.cache.fetch("cartridges_by_cat_#{category}", :expires_in => DURATION){ cartridges.select{ |cart| cart.categories.include?(category) } }
    carts.concat(app.downloaded_cartridge_instances.values.select{ |cart| cart.categories.include?(category) }) if app
    carts
  end

  # Returns the first cartridge that provides the specified feature.
  # @note This method matches both features provided by the cartridge as well as the cartridge name.
  #
  # == Parameters:
  # feature::
  #   Name of feature to look for.
  def self.find_cartridge(requested_feature, app=nil)
    if app
      app.downloaded_cartridge_instances.values.each do |cart|
        return cart if cart.features.include?(requested_feature)
        return cart if cart.names.include?(requested_feature)
        return cart if cart.original_name == requested_feature
      end
      if cart = app.cartridge_instances[requested_feature]
        return cart
      end
    end

    matches = Rails.cache.fetch("carts_by_feature_#{requested_feature}", :expires_in => DURATION){ self.find_all_cartridges(requested_feature) }

    return nil if matches.blank?

    cart =
      if matches.length == 1
        matches.first
      else
        redhat = matches.select{ |c| c.cartridge_vendor == "redhat"}
        if redhat.present?
          redhat.sort_by(&OpenShift::Cartridge::VERSION_ORDER).last
        end
      end

    if cart
      app.cartridge_instances[cart.name] = cart if app
      return cart
    end

    #if there are more than one match and none by redhat raise an exception
    choices = matches.inject([]) do |arr, c|
      arr << c.name
    end

    raise OpenShift::UserException.new("More that one cartridge was found matching #{requested_feature}.  Please select one of #{choices.to_sentence}")
  end

  # Returns the first cartridge that provides the specified feature,
  # same as find_cartridge, but raise an OOException if no cartridge is
  # found.
  def self.find_cartridge_or_raise_exception(feature, app)
    find_cartridge(feature, app) or raise OpenShift::OOException.new("The application '#{app.name}' requires '#{feature}' but a matching cartridge could not be found")
  end

  def self.find_all_cartridges(requested_feature)
    matching_carts = []
    (CartridgeType.provides(requested_feature) + self.get_all_cartridges).each do |cart|
      return [cart] if cart === requested_feature
      if cart.has_feature?(requested_feature)
        cart = cart.cartridge if cart.respond_to? :cartridge
        matching_carts << cart
      end
    end
    matching_carts
=begin
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
=end
  end

  def self.cartridge_from_data(data)
    raw = OpenShift::Runtime::Manifest.manifest_from_yaml(data['original_manifest'])
    manifest = OpenShift::Runtime::Manifest.projected_manifests(raw, data["version"])
    cart = OpenShift::Cartridge.new.from_descriptor(manifest.manifest)
    cart.manifest_text = data['original_manifest']
    cart.manifest_url = data['url']
    cart
  end

  #
  # Given a set of features and URLs to cartridge manifests, assemble
  # a list of cartridge instances to install.
  #
  # Takes as input an array of strings or hashes - accepted keys are:
  # - name: the name of a feature
  # - url: a URL to a cartridge manifest
  # - version: a specific version of a URL version to download
  # - gear_size: a gear size for this cartridge.  must be valid
  #
  def self.find_and_download_cartridges(specs, field='cartridge', enforce_download_limit=false)
    downloads = []

    if enforce_download_limit
      download_cartridges_enabled = Rails.configuration.openshift[:download_cartridges_enabled]
      download_limit = (Rails.configuration.downloaded_cartridges[:max_downloaded_carts_per_app] rescue 5) || 5
      download_count = specs.select{ |f| f[:url] }.length
      if download_count > 0
        if not download_cartridges_enabled
          raise OpenShift::UserException.new("You may not add downloadable cartridges to applications.", 109, field)
        elsif download_count > download_limit
          raise OpenShift::UserException.new("You may not specify more than #{download_limit} cartridges to be downloaded.", 109, field)
        end
      end
    end

    cartridges = specs.inject([]) do |arr, spec|
      spec = {name: spec} if spec.is_a?(String)
      if spec[:url]
        downloads << spec
        next arr
      end

      name = spec[:name]
      if CartridgeInstance.check_feature?(name)
        cart = find_cartridge(name)
      end
      raise OpenShift::UserException.new("Invalid cartridge '#{name}' specified.", 109, field) if cart.nil?

      # carts defined with a manifest URL are downloaded each time
      if cart.manifest_url
        downloads << spec.except(:name).merge!(url: cart.manifest_url, version: cart.version)
        next arr
      end

      instance = CartridgeInstance.new(cart, spec)
      arr << instance
    end

    # download URL cartridges
    downloads.each do |spec|
      begin
        url, version = spec.values_at(:url, :version)

        text = download_from_url(url, field)
        versions = OpenShift::Runtime::Manifest.manifests_from_yaml(text)

        if version.present? && versions.present?
          manifest = versions.find{ |v| v.version == version } or
            raise OpenShift::UserException.new("The cartridge '#{url}' does not define a version '#{version}'.", 109, field)
        else
          manifest = versions.first or
            raise OpenShift::UserException.new("The URL '#{url}' does not define a valid cartridge.", 109, field)
        end

        manifest.check_reserved_vendor_name

        cart = OpenShift::Cartridge.new.from_descriptor(manifest.manifest)
        cart.manifest_text = text
        cart.manifest_url = url
        instance = CartridgeInstance.new(cart, spec)
        cartridges << instance

      rescue OpenShift::ElementError => e
        raise OpenShift::UserException.new("The provided downloadable cartridge '#{url}' cannot be loaded: #{e.message}", 109, field)
      end
    end

    cartridges
  end

  def self.download_from_url(url, field=nil)
    cartridge_conf = Rails.configuration.downloaded_cartridges || {}

    client = if cartridge_conf[:http_proxy].present?
      HTTPClient.new(cartridge_conf[:http_proxy])
    else
      HTTPClient.new
    end

    # Configuration
    client.read_block_size =        cartridge_conf[:max_cart_size] || 20480
    client.connect_timeout =        cartridge_conf[:connect_timeout] || 2
    client.receive_timeout =        cartridge_conf[:max_download_time] || 10
    client.follow_redirect_count =  cartridge_conf[:max_download_redirects] || 2

    manifest = ""

    if URI.parse(url).kind_of? URI::HTTP
      begin
        Rails.logger.debug("Downloading #{url}...")
        Timeout.timeout(client.receive_timeout) do
          client.get_content(url, nil, {"X-OpenShift-Cartridge-Download"=>""}) do |chunk|
            manifest << chunk
            if manifest.length > client.read_block_size
              raise OpenShift::UnfulfilledRequirementException.new(url)
            end
          end
        end
      rescue Timeout::Error
        raise OpenShift::UserException.new("The cartridge manifest at '#{url}' took too long to retrieve.", 109, field)
      rescue HTTPClient::BadResponseError => be
        raise OpenShift::UserException.new("The cartridge manifest at '#{url}' was not available (status code: #{be.res.status_code}).", 109, field)
      rescue => e
        Rails.logger.debug(e.backtrace)
        raise OpenShift::UserException.new("The cartridge manifest at '#{url}' could not be downloaded: #{e.message}", 109, field)
      end
    end

    raise OpenShift::UserException.new("The cartridge manifest at '#{url}' was empty.", 109, field) if manifest.blank?

    manifest
  end

  # Returns an Array of all cartridge objects
  def self.get_all_cartridges
    #CartridgeType.all
    Rails.cache.fetch("all_cartridges", :expires_in => DURATION) do
      carts = OpenShift::ApplicationContainerProxy.find_one.get_available_cartridges
      CartridgeType.active.each do |type|
        carts << type.cartridge unless carts.any?{ |cart| cart.name == type.name }
      end
      carts
    end
  end
end
