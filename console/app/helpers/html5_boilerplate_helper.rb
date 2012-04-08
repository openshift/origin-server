module Html5BoilerplateHelper
  # Create a named haml tag to wrap IE conditional around a block
  # http://paulirish.com/2008/conditional-stylesheets-vs-css-hacks-answer-neither
  def ie_tag(name=:body, attrs={}, &block)
    attrs.symbolize_keys!
    haml_concat("<!--[if lt IE 7]> #{ tag(name, add_class('ie6', attrs), true) } <![endif]-->".html_safe)
    haml_concat("<!--[if IE 7]>    #{ tag(name, add_class('ie7', attrs), true) } <![endif]-->".html_safe)
    haml_concat("<!--[if IE 8]>    #{ tag(name, add_class('ie8', attrs), true) } <![endif]-->".html_safe)
    haml_concat("<!--[if gt IE 8]><!-->".html_safe)
    haml_tag name, attrs do
      haml_concat("<!--<![endif]-->".html_safe)
      block.call
    end
  end

  def ie_html(attrs={}, &block)
    ie_tag(:html, attrs, &block)
  end

  def ie_body(attrs={}, &block)
    ie_tag(:body, attrs, &block)
  end

  def google_account_id
    ENV['GOOGLE_ACCOUNT_ID'] || google_config(:google_account_id)
  end

  def google_api_key
    ENV['GOOGLE_API_KEY'] || google_config(:google_api_key)
  end

  def remote_jquery(version)
    if Rails.env == 'development'
      "'jquery', '#{version}', {uncompressed:true}"
    else
      "'jquery', '#{version}'"
    end
  end

  def local_jquery(version)
    if Rails.env == 'development'
      "#{version}/jquery.js"
    else
      "#{version}/jquery.min.js"
    end
  end

private

  def add_class(name, attrs)
    classes = attrs[:class] || ''
    classes.strip!
    classes = ' ' + classes if !classes.blank?
    classes = name + classes
    attrs.merge(:class => classes)
  end

  def google_config(key)
    configs = YAML.load_file(File.join(Rails.root, 'config', 'google.yml'))[Rails.env.to_sym] rescue {}
    configs[key]
  end
end