module Console::ModelHelper
  def cartridge_info(cartridge, application)
    case
    when cartridge.jenkins_client?
      [
        link_to('See Jenkins Build jobs', application.build_job_url, :title => 'Jenkins is currently running builds for your application'),
        link_to('(configure)', application_building_path(application), :title => 'Remove or change your Jenkins configuration'),
      ].join(' ').html_safe
    when cartridge.haproxy_balancer?
      link_to "See HAProxy status page", application.scale_status_url
    when cartridge.database?
      name, _ = cartridge.data(:database_name)
      if name
        user, _ = cartridge.data(:username)
        password, _ = cartridge.data(:password)
        content_tag(:span,
          if user && password
            (@info_id ||= 0)
            link_id = "db_link_#{@info_id += 1}"
            span_id = "db_link_#{@info_id += 1}"
            "Database: <strong>#{h name}</strong>, User: <strong>#{h user}</strong>, Password: <a href=\"javascript:;\" id=\"#{link_id}\" data-unhide=\"##{span_id}\" data-hide-parent=\"##{link_id}\">show</a><span id=\"#{span_id}\" class=\"hidden\"> <strong>#{h password}</strong></span>".html_safe
          else
            "Database: <strong>#{name}</strong>"
          end
        )
      end
    else
      url, name = cartridge.data(:connection_url)
      if url
        link_to name, url, :target => '_blank'
      end
    end
  end

  def gear_group_state(states)
    css_class = if states.all? {|s| s == :started}
        'state_started'
      elsif states.none? {|s| s == :started}
        'state_stopped'
      end

    content_tag(:span, gear_group_states(states), :class => css_class)
  end

  def gear_group_count(gears)
    types = gears.inject({}){ |h,g| h[g.gear_profile.to_s] ||= 0; h[g.gear_profile.to_s] += 1; h }
    return 'None' if types.empty?
    types.keys.sort.map do |k|
      "#{types[k]} #{k.humanize.downcase}"
    end.to_sentence
  end

  def available_gears_warning(writeable_domains)
    if writeable_domains.present?
      if !writeable_domains.find(&:allows_gears?)
        has_shared = writeable_domains.find {|d| !d.owner? }
        if has_shared
          "The owners of the available domains have disabled all gear sizes from being created."
        else
          "You have disabled all gear sizes from being created."
        end
      elsif !writeable_domains.find(&:has_available_gears?)
        "There are not enough free gears available to create a new application. You will either need to scale down or delete existing applications to free up resources."
      end
    end
  end

  def new_application_gear_sizes(writeable_domains, user_capabilities)
    gear_sizes = user_capabilities.allowed_gear_sizes
    if writeable_domains.present?
      gear_sizes = writeable_domains.map(&:capabilities).map(&:allowed_gear_sizes).flatten.uniq
    end
    gear_sizes
  end

  def estimate_domain_capabilities(selected_domain_name, writeable_domains, can_create, user_capabilities)
    if (selected_domain = writeable_domains.find {|d| d.name == selected_domain_name})
      [selected_domain.capabilities, selected_domain.owner?]
    elsif writeable_domains.length == 1
      [writeable_domains.first.capabilities, writeable_domains.first.owner?]
    elsif can_create and writeable_domains.length == 0
      [user_capabilities, true]
    else
      [nil, nil]
    end
  end

  def domains_for_select(domains)
    domains.sort_by(&:name).map do |d|
      capabilities = d.capabilities
      if capabilities
        [d.name, d.name, {
          "data-gear-sizes" => capabilities.allowed_gear_sizes.join(','),
          "data-gears-free" => capabilities.gears_free
        }]
      else
        [d.name, d.name]
      end
    end
  end

  def web_cartridge_scale_title(cartridge)
    if cartridge.current_scale == cartridge.scales_from
      'Your web cartridge is running on the minimum amount of gears and will scale up if needed'
    elsif cartridge.current_scale == cartridge.scales_to
      'Your web cartridge is running on the maximum amount of gears and cannot scale up any further'
    else
      'Your web cartridge is running multiple copies to handle increased web traffic'
    end
  end

  def web_cartridge_scale_label(cartridge)
    suffix = case
      when cartridge.scales_from == cartridge.scales_to
      when cartridge.current_scale == cartridge.scales_from
        " (max #{cartridge.scales_to})"
      when cartridge.current_scale == cartridge.scales_to
        " (min #{cartridge.scales_from})"
      else
        " (min #{cartridge.scales_to}, max #{cartridge.scales_to})"
      end
    "Routing to #{pluralize(cartridge.current_scale, 'web gear')}#{suffix}"
  end

  def application_gear_count(application)
    return 'None' if application.gear_count == 0
    "#{application.gear_count} #{application.gear_profile.to_s.humanize.downcase}"
  end

  def cartridge_gear_group_count(group)
    return 'None' if group.gears.empty?
    "#{group.gears.length} #{group.gear_profile.to_s.humanize.downcase}"
  end

  def gear_group_count_title(total_gears)
    "OpenShift runs each cartridge inside one or more gears on a server and is allocated a fixed portion of CPU time and memory use."
  end

  def cartridge_storage(cart)
    storage_string(cart.total_storage)
  end

  def scaled_cartridge_storage(cart)
    storage_string(cart.total_storage, cart.current_scale)
  end

  def storage_string(quota,multiplier = 0)
    parts = []
    if multiplier > 1
      parts << "#{multiplier} x"
    end
    parts << "%s GB" % quota
    parts.join(' ').strip
  end

  def scaling_max(*args)
    args.unshift(1)
    args.select{ |i| i != nil && i != -1 }.max
  end
  def scaling_min(*args)
    args.unshift(1)
    args.select{ |i| i != nil && i != -1 }.min
  end

  def scale_range(from, to, max, max_choices)
    limit = to == -1 ? max : to
    return if limit > max_choices
    (from .. limit).map{ |i| [i.to_s, i] }
  end
  def scale_from_options(obj, max, max_choices=20)
    if range = scale_range(obj.supported_scales_from, obj.supported_scales_to, max, max_choices)
      {:as => :select, :collection => range, :include_blank => false}
    else
      {:as => :string}
    end
  end
  def scale_to_options(obj, max, max_choices=20)
    if range = scale_range(obj.supported_scales_from, obj.supported_scales_to, max, max_choices)
      range << ['All available', -1] if obj.supported_scales_to == -1
      {:as => :select, :collection => range, :include_blank => false}
    else
      {:as => :string, :hint => 'Use -1 to scale to your current account limits'}
    end
  end

  def storage_options(min,max)
    {:as => :select, :collection => (min..max), :include_blank => false}
  end

  def scale_options
    [['No scaling',false],['Scale with web traffic',true]]
  end

  def can_scale_application_type(type, capabilities=nil)
    type.scalable?
  end

  def cannot_scale_title(type, capabilities=nil)
    unless can_scale_application_type(type, capabilities)
      "This application shares filesystem resources and can't be scaled."
    end
  end

  def warn_may_not_scale(type, capabilities=nil)
    if type.may_not_scale?
      "This application may require additional work to scale. Please see the application's documentation for more information."
    end
  end

  def in_groups_by_tag(ary, tags)
    groups = {}
    other = ary.reject do |t|
      tags.any? do |tag|
        (groups[tag] ||= []) << t if t.tags.include?(tag)
      end
    end
    groups = tags.map do |tag|
      types = groups[tag]
      if types
        if types.length < 2
          other.concat(types)
          nil
        else
          [tag, types]
        end
      end
    end.compact
    [groups, other]
  end

  def common_tags_for(ary)
    ary.length < 2 ? [] : ary.inject(nil){ |tags, a| tags ? (a.tags & tags) : a.tags } || []
  end

  def class_for_cartridge(cart)
    %w{jboss jbossews ruby php perl nodejs python mongodb mysql postgresql zend diy jenkins}.each do |c|
      return "icon-#{c}" if cart.name.match(c)
    end
    return "icon-cartridge"
  end
end
