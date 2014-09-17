#
# CartridgeCache abstracts finding and locating cartridges available to the server.
#
# If you need to access the cartridges on an application use the Application#cartridges
# method.  Only use methods here when attempting to locate a cartridge by a specific
# criteria.
#
require 'httpclient'

class CartridgeCache

  DURATION = 20.minutes

  #
  # Returns an Array of web framework cartridge names.
  #
  def self.web_framework_names(include_obsolete=true)
    Rails.cache.fetch("web_framework_cartridge_names", :expires_in => DURATION) do
      carts = CartridgeType.active.in(categories: 'web_framework')
      carts = carts.not_in(obsolete: true) unless include_obsolete

      carts.only(:name).limit(25).map(&:name).uniq.sort
    end
  end

  #
  # Returns an Array of names of non web framework cartridges.
  #
  def self.other_names
    Rails.cache.fetch("other_cartridge_names", :expires_in => DURATION) do
      CartridgeType.active.not_in(categories: 'web_framework').only(:name).limit(25).map(&:name).uniq.sort
    end
  end

  #
  # Return an exact match for id, nil if no matches exist.  As a special sub case,
  # allow a cartridge to be located by its id within an application if a user is
  # provided.  This allows exact recreation of a previous cartridge instance (
  # if the content in the url has not changed).
  #
  def self.find_cartridge_by_id_for_user(id, as_user)
    if cart = LRU_CACHE[id]
      return cart
    end
    if type = CartridgeType.where(id: id).first
      return lru_cache(type.cartridge)
    end
    if as_user
      if app = Application.where('component_instances.cartridge_id' => id).
               accessible(as_user).only(:component_instances).hint("component_instances.cartridge_id" => 1).
               first
        app.cartridges.detect{ |c| id === c.id }
      end
    end
  end

  #
  # Return an exact match for id, nil if no matches exist.
  #
  def self.find_cartridge_by_id(id, app=nil)
    if app && (cart = app.cartridges.detect{ |c| id === c.id })
      return cart
    end
    if cart = LRU_CACHE[id]
      return cart
    end
    type = CartridgeType.where(id: id).first
    lru_cache(type.cartridge) if type
  end

  #
  # Return an exact match for name, nil if no matches exist, or raise an error if
  # there is more than one relevant match.  If one or more cartridges that are
  # provided by 'redhat' are found, then the most recent will be returned if all of
  # of the matches have a common base (like 'php' or 'ruby').
  #
  def self.find_cartridge_by_base_name(name, app=nil)
    matches = find_cartridges_by_base_name(name, app)
    return nil if matches.blank?
    return matches.first if matches.length == 1

    names = matches.map(&:name).uniq.sort
    raise OpenShift::UserException.new("More than one cartridge was found matching #{name}.  Please select one of #{names.to_sentence}", 197, nil, nil, nil, {:cartridge_names => names})
  end

  #
  # Return cartridges that match the criteria for find_cartridge_by_base_name
  #
  def self.find_cartridges_by_base_name(name, app=nil)
    matches = scope_to_name(name, app)
    return [] if matches.blank?
    matches.each{ |m| lru_cache(m) }
    return matches if matches.length == 1

    redhat = matches.select{ |c| c.cartridge_vendor == "redhat"}
    return [redhat.sort_by(&OpenShift::Cartridge::VERSION_ORDER).last] if redhat.map(&:original_name).uniq.length == 1

    matches
  end

  def self.find_cartridges_by_base_names(names, app=nil)
    names.map{ |name| find_cartridges_by_base_name(name, app).first }.compact
  end

  #
  # Return an exact match for name, or attempt to locate a matching name or
  # feature.  Should only be used in limited cases where existing behavior
  # requires checking the Provides of a cartridge (web_proxy).
  #
  def self.find_cartridge_by_feature(feature, app=nil)
    matches = scope_to_feature(feature, app)
    return nil if matches.blank?
    return matches.first if matches.length == 1

    redhat = matches.select{ |c| c.cartridge_vendor == "redhat"}
    return redhat.sort_by(&OpenShift::Cartridge::VERSION_ORDER).last if redhat.map(&:original_name).uniq.length == 1

    #if there are more than one match and none by redhat raise an exception
    names = matches.map(&:name).uniq.sort
    raise OpenShift::UserException.new("More than one cartridge was found matching #{name}.  Please select one of #{names.to_sentence}", 197, nil, nil, nil, {:cartridge_names => names})
  end

  # Returns the active cartridge matching the provided name (the full_identifier)
  #
  # == Parameters:
  # feature::
  #   Name of cartridge to look for.
  def self.find_cartridge(name, app=nil)
    if app
      cart = app.cartridges.detect{ |c| c.name == name }
      return cart if cart
    end

    type = CartridgeType.active.where(name: name).first || CartridgeType.where(name: name).first
    lru_cache(type.cartridge) if type
  end

  # Return cartridges in bulk for names
  #
  # TODO: more efficiently bulk load cartridges
  #
  def self.find_cartridges(names, app=nil)
    names.map{ |name| find_cartridge(name, app) }
  end

  def self.find_serialized_cartridge(hash, app=nil)
    return nil unless hash.present? && hash['manifest_text'].present?
    cart = OpenShift::Cartridge.new(JSON.parse(hash['manifest_text']), true)
    cart.manifest_text = hash['manifest_text']
    cart.manifest_url = hash['manifest_url']
    lru_cache(cart)
  end

  def self.find_serialized_cartridges(hashes, app=nil)
    downloaded, hashes = hashes.partition{ |c| c['manifest_text'].present? }
    ids, named = hashes.partition{ |c| c['id'].present? }
    downloaded.map{ |c| find_serialized_cartridge(c, app) } + ids.map{ |c| find_cartridge_by_id(c['id'], app) } + find_cartridges(named.map{ |c| c['name'] }, app)
  end

  # DEPRECATED: Do not use
  def self.find_all_cartridges(requested_feature)
    matching_carts = []
    CartridgeType.active.provides(requested_feature).each do |cart|
      return [cart] if cart === requested_feature
      if cart.has_feature?(requested_feature)
        cart = cart.cartridge if cart.respond_to? :cartridge
        matching_carts << lru_cache(cart)
      end
    end
    matching_carts
  end

  def self.find_requires_for(cartridge)
    Rails.cache.fetch("cartridge_requires_for_#{cartridge.id}", :expires_in => DURATION) do
      Array(cartridge.requires + cartridge.configure_order).uniq.map do |required|
        required = Array(required)
        next if (required & cartridge.names).present?
        matches = []
        if names = required.compact.map(&:to_s).presence
          CartridgeType.active.provides(names).each do |cart|
            if (cart.names & names).present?
              matches << lru_cache(cart.cartridge)
            end
          end
          matches.compact.sort_by(&OpenShift::Cartridge::NAME_PRECEDENCE_ORDER).map(&:name).uniq.presence || required
        end
      end.compact
    end
  end

  def self.cartridge_from_data(data)
    raw = OpenShift::Runtime::Manifest.manifest_from_yaml(data['original_manifest'])
    manifest = OpenShift::Runtime::Manifest.projected_manifests(raw, data["version"]).manifest
    cart = OpenShift::Cartridge.new(manifest, true)
    cart.manifest_text = manifest.to_json
    cart.manifest_url = data['url']
    lru_cache(cart)
  end

  def self.cartridge_to_data(cart)
    {
      "versioned_name" => cart.full_identifier,
      "version" => cart.version,
      "url" => cart.manifest_url,
      "original_manifest" => JSON.parse(cart.manifest_text).to_yaml,
    }
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
  def self.find_and_download_cartridges(specs, field='cartridge', enforce_download_limit=false, as_user=nil)
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
        downloads << spec.except(:id)
        next arr
      end

      cart =
        if (name = spec[:name]) && CartridgeInstance.check_feature?(name)
          find_cartridge_by_base_name(name) or
            raise OpenShift::UserException.new("Invalid cartridge '#{name}' specified.", 109, field)
        elsif (id = spec[:id]) && CartridgeInstance.check_id?(id)
          find_cartridge_by_id_for_user(id, as_user) or
            raise OpenShift::UserException.new("Invalid cartridge identifier '#{id}' specified.", 109, field)
        end

      raise OpenShift::UserException.new("Invalid cartridge '#{name}' specified.", 109, field) if cart.nil?

      # carts defined with a manifest URL are downloaded each time
      if cart.manifest_url.present? # && not a reusable docker cart
        downloads << spec.except(:name).merge!(url: cart.manifest_url, version: cart.version, id: cart.id)
        next arr
      end

      instance = CartridgeInstance.new(cart, spec)
      arr << instance
    end

    # download URL cartridges
    downloads.each do |spec|
      begin
        url, version, id = spec.values_at(:url, :version, :id)

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

        manifest.manifest["Id"] = id || Moped::BSON::ObjectId.new.to_s
        cart = OpenShift::Cartridge.new(manifest.manifest, true)
        cart.manifest_text = manifest.manifest.to_json
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

    # Fix the case when SSL certificate does not support SSLv3 which is default
    # for HTTPClient.
    #
    client.ssl_config.ssl_version = 'SSLv23'

    manifest = ""

    if URI.parse(url).kind_of? URI::HTTP
      begin
        Rails.logger.debug("Downloading #{url}...")
        Timeout.timeout(client.receive_timeout) do
          client.get_content(url, nil, {"X-OpenShift-Cartridge-Download"=>""}) do |chunk|
            manifest << chunk
            if manifest.length > client.read_block_size
              raise OpenShift::UserException.new("The cartridge manifest at '#{url}' must be smaller than #{client.read_block_size} bytes.", 109, field)
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

  private
    LRU_CACHE = AgedCache.new(200)

    def self.lru_cache(cartridge)
      LRU_CACHE[cartridge.id.to_s] = cartridge if cartridge.id
      cartridge
    end

    # Returns a Criteria scope of all active cartridges
    def self.get_all_cartridges
      CartridgeType.active
    end

    def self.scope_to_feature(feature, app=nil)
      if app
        carts = app.cartridges.select{ |c| c.features.include?(feature) }
        return carts if carts.present?
      end
      CartridgeType.active.where(provides: feature).select{ |c| c.features.include?(feature) }.map(&:cartridge)
    end

    def self.scope_to_name(name, app=nil)
      if app
        carts = app.cartridges.select{ |c| c.names.include?(name) }
        return carts if carts.present?
      end
      if cart = CartridgeType.active.where(name: name).first
        return [cart.cartridge]
      end
      CartridgeType.active.where(provides: name).select{ |c| c.names.include?(name) }.map(&:cartridge)
    end
end
