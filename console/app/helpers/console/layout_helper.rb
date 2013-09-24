require 'enumerator'

module Console::LayoutHelper

  def in_columns_of(count, arr)
    arr.enum_for(:each_with_index).inject(Array.new(count) {[]}){ |a, (item,i)| a[i % count] << item; a }
  end

  def in_balanced_columns_of(count, groups)
    columns = Array.new(count){ [] }
    counts = Array.new(count,0)
    groups.each do |group|
      column = counts.index(counts.min)
      columns[column] << group
      counts[column] += group[1].size
    end
    columns
  end

  def navigation_tabs(options={}, &block)
    content = capture(&block)
    content_tag(:ul, content, :class => 'nav')
  end

  def navigation_tab(name, options={})
    action = options[:action]
    active = active_tab == name || (name.to_s == controller_name) && (action.nil? || action.to_s == controller.action_name)
    content_tag(
      :li,
      link_to(
        options[:name] || ActiveSupport::Inflector.humanize(name),
        url_for({
          :action => action || :index,
          :controller => name
        })
      ),
      active ? {:class => 'active'} : nil)
  end

  #
  # Renders the flash only once.  In normal rails flow templates are rendered first
  # and so the flash will be displayed in the template - otherwise the layout has
  # an opportunity to render it.
  #
  def flashes
    return if @flashed_once || flash.nil?; @flashed_once = true
    tags = []
    flash.each do |key, value|
      (value.kind_of?(Array) ? value : [value]).each do |value|
        next if value.blank?
        tags << content_tag(flash_element_for(key), value, :class => alert_class_for(key))
      end
    end
    content_tag(:div, tags.join.html_safe, :id => 'flash') unless tags.empty?
  end

  def flash_element_for(key)
    case key
    when :info_pre
      :pre
    else
      :div
    end
  end

  def control_group(*args, &block)
    opts = args.extract_options!
    classes = ['control-group']
    classes << 'control-group-important' if opts[:important]
    data = if opts[:errors] || args.first == true
        classes << 'error'
        {:server_error => true}    
      end
    content_tag(:div, capture_haml{ yield }.html_safe, :class => classes.join(' '), :data => data)
  end

  def alert_class_for(key)
    case key
    when :success
      'alert alert-success'
    when :notice
      'alert alert-info'
    when :error
      'alert alert-error'
    when :info
      'alert alert-info'
    when :info_pre
      'cli'
    else
      Rails.logger.debug "Handling alert key #{key.inspect}"
      'alert'
    end
  end

  def render_thumbnails( collection, options )
    unless collection.empty?
      content_tag(
        :ul,
        collection.collect { |o|
          content_tag(
            :li,
            render(options.merge(:object => o)).html_safe,
            :class => options[:grid] || 'span3'
          )
        }.join.html_safe,
        :class => 'thumbnails'
      )
    end
  end

  AppWizardStepsCreate = [
    {
      :name => 'Choose a type of application',
      :link => 'application_types_path'
    },
    {
      :name => 'Configure the application'
    },
    {
      :name => 'Next steps'
    }
  ]

  def app_wizard_steps_create(active, options={})
    wizard_steps(AppWizardStepsCreate, active, options)
  end

  CartridgeWizardStepsCreate = [
    {
      :name => 'Choose a cartridge type',
      :link => 'application_cartridge_types_path'
    },
    {
      :name => 'Configure the cartridge'
    },
    {
      :name => 'Next steps'
    }
  ]

  def cartridge_wizard_steps_create(active, options={})
    wizard_steps(CartridgeWizardStepsCreate, active, options)
  end

  def show_description(description, opts={})
    simple_format(truncate(description, {:length => opts[:length] || 550, :separator => "\n\n", :omission => ""}.reverse_merge!(opts)), opts)
  end

  def wizard_steps(items, active, options={})
    content_tag(
      :ol,
      (items + [options[:and]].compact).each_with_index.map do |item, index|
        name = item[:name]
        content = if item[:link] and ((index < active and !options[:completed]) or options[:active])
          link_to(name, send("#{item[:link]}")).html_safe
        else
          name
        end

        content = content_tag(:span, [
          content_tag(:i, index+1),
          content].join.html_safe)

        classes = if index < active
          'completed'
        elsif index == active
          'active'
        end
        content_tag(:li, content, :class => classes)
      end.join.html_safe,
      :class => 'wizard'
    )
  end

  def take_action(link, text, *args)
    options = args.extract_options!
    link_to link, {:class => (['action-call'] << options[:class]).join(' ')}.reverse_merge!(options) do
      ([content_tag(:div, text.html_safe)] <<
        args.collect { |text| content_tag(:div, text, :class => 'highlight') } <<
        content_tag(:div, '>', :class => 'highlight-arrow')).join.html_safe
    end
  end

  def greetings_for_select
    [ 'Mr.', 'Mrs.', 'Ms.', 'Miss', 'Dr.', 'Hr.', 'Sr.' ]
  end

  def map_to_sentence(items, &block)
    items.map{ |c| capture_haml{ yield c }.strip }.to_sentence.html_safe
  end

  HIDDEN_TAGS = [:featured, :framework, :web_framework, :experimental, :in_development, :cartridge, :service, :domain_scope]
  IMPORTANT_TAGS = [:new, :premium]

  def application_type_tags(tags)
    (tags - HIDDEN_TAGS).uniq.sort!.partition{ |t| IMPORTANT_TAGS.include?(t) }.flatten.map do |tag| 
      link_to tag.to_s.humanize, application_types_path(:tag => tag), :class => "label label-#{tag}"
    end.join.html_safe
  end

  def us_states_for_select
    [
      ['Alabama', 'AL'],
      ['Alaska', 'AK'],
      ['Arizona', 'AZ'],
      ['Arkansas', 'AR'],
      ['California', 'CA'],
      ['Colorado', 'CO'],
      ['Connecticut', 'CT'],
      ['Delaware', 'DE'],
      ['District of Columbia', 'DC'],
      ['Florida', 'FL'],
      ['Georgia', 'GA'],
      ['Hawaii', 'HI'],
      ['Idaho', 'ID'],
      ['Illinois', 'IL'],
      ['Indiana', 'IN'],
      ['Iowa', 'IA'],
      ['Kansas', 'KS'],
      ['Kentucky', 'KY'],
      ['Louisiana', 'LA'],
      ['Maine', 'ME'],
      ['Maryland', 'MD'],
      ['Massachusetts', 'MA'],
      ['Michigan', 'MI'],
      ['Minnesota', 'MN'],
      ['Mississippi', 'MS'],
      ['Missouri', 'MO'],
      ['Montana', 'MT'],
      ['Nebraska', 'NE'],
      ['Nevada', 'NV'],
      ['New Hampshire', 'NH'],
      ['New Jersey', 'NJ'],
      ['New Mexico', 'NM'],
      ['New York', 'NY'],
      ['North Carolina', 'NC'],
      ['North Dakota', 'ND'],
      ['Ohio', 'OH'],
      ['Oklahoma', 'OK'],
      ['Oregon', 'OR'],
      ['Pennsylvania', 'PA'],
      ['Puerto Rico', 'PR'],
      ['Rhode Island', 'RI'],
      ['South Carolina', 'SC'],
      ['South Dakota', 'SD'],
      ['Tennessee', 'TN'],
      ['Texas', 'TX'],
      ['Utah', 'UT'],
      ['Vermont', 'VT'],
      ['Virginia', 'VA'],
      ['Washington', 'WA'],
      ['West Virginia', 'WV'],
      ['Wisconsin', 'WI'],
      ['Wyoming', 'WY']
    ]
  end

  #
  # Only use in content that will be generated to asset form, significant
  # performance penalties will apply in production environments.
  #
  def asset_data_uri(path)
    a = asset(path)
    base64 = Base64.encode64(a.to_s).gsub(/\s+/, "")
    "data:#{a.content_type};base64,#{Rack::Utils.escape(base64)}"
  end 
  #
  # Only use in content that will be generated to asset form, significant
  # performance penalties will apply in production environments.
  #
  def asset(path)
    Rails.application.assets.find_asset(path)
  end
end
