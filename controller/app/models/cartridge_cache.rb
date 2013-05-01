# Cache of cartridge manifest metadata. Used to reduce the number of calls 
# to the Node to retrieve cartridge information.
class CartridgeCache
  include CacheHelper
  
  # Returns an Array of Cartridge objects
  def self.cartridges
    CacheHelper.get_cached("all_cartridges", :expires_in => 21600.seconds) do
      carts = OpenShift::ApplicationContainerProxy.find_one().get_available_cartridges
      raise OpenShift::NodeException.new if carts.empty?
      carts
    end
  rescue OpenShift::NodeException => e
    Rails.logger.error <<-"ERROR"
    In #{__FILE__} cartridges method:
      Error while querying cartridge list. This may be because no node hosts responded.
      Please ensure you have installed node hosts and they are responding to "mco ping".
      Exception was: #{e.inspect}
    ERROR
    return []
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
        cartnames << app.community_cartridges.values.keys.dup
        cartnames.flatten
      end
      return cartnames
    else
      cart_type = "web_framework" if cart_type == "standalone"
      find_cartridge_by_category(cart_type, app).map{ |cart| cart.name }
    end
  end
  
  def self.find_cartridge_by_component(component_name, app=nil)
    if app
      app.community_cartridges.values.each do |cart|
        return cart if cart.has_component?(component_name)
        return cart if cart.name == component_name
      end
    end
    carts = self.cartridges
    carts.each do |cart|
      return cart if cart.has_component?(component_name)
      return cart if cart.name == component_name
    end
    return nil
  end
  
  def self.find_cartridge_by_category(cat, app=nil)
    global_carts = CacheHelper.get_cached("cartridges_by_cat_#{cat}", :expires_in => 1.day) {cartridges.select{|cart| cart.categories.include?(cat) }}
    if app
      app_local_community_carts = app.community_cartridges.values.select { |cart| cart.categories.include?(cat) }
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
  def self.find_cartridge(feature, app=nil)
    app.community_cartridges.values.each do |cart|
      return cart if cart.features.include?(feature)
      return cart if cart.name == feature
    end if app
    carts = self.cartridges
    carts.each do |cart|
      return cart if cart.features.include?(feature)
      return cart if cart.name == feature
    end
    return nil
  end

  def self.download_from_url(url)
    max_dl_time = (Rails.application.config.downloaded_cartridges[:max_download_time] rescue 10) || 10
    max_file_size = (Rails.application.config.downloaded_cartridges[:max_cart_size] rescue 20480) || 20480
    max_redirs = (Rails.application.config.downloaded_cartridges[:max_download_redirects] rescue 2) || 2
    `curl --max-time #{max_dl_time} --connect-timeout 2 --location --max-redirs #{max_redirs} --max-filesize #{max_file_size} -k #{url}`
  end

  def self.fetch_community_carts(urls)
    cmap = {}
    return cmap if urls.nil?
    urls.each do |url|
       manifest_str = download_from_url(url)
       if manifest_str.length == 0
         raise OpenShift::UserException.new("Invalid cartridge, error downloading from url '#{url}' ", 109)  
       end
       chash = YAML.load(manifest_str)
       # TODO: check versions and create multiple of them
       cmap[chash["Name"]] = { "url" => url, "manifest" => manifest_str }
    end
    return cmap
  end

end
