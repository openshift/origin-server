unless Console.config.disable_css
  #
  # Stylesheets are assumed to be generated into Rails tmp/stylesheets,
  # either dynamically in development, or by the RPM build in production
  #
  options = {
    :urls => ['/stylesheets'],
    :root => "#{Rails.root}/tmp"
  }

  Sass::Plugin.options[:css_location] = Rails.root.join("tmp", "stylesheets")

  Sass::Plugin.add_template_location(Console::Engine.root.join("app", "stylesheets"))
  Sass::Plugin.add_template_location(Rails.root.join("app", "stylesheets"))

  #
  # All production environments pregenerate CSS using the RPM build, development
  # environments use autogeneration
  #
  if Rails.env.development?
    Rails.configuration.middleware.insert_after('Sass::Plugin::Rack', 'Rack::Static', options)
  else
    Rails.configuration.middleware.insert_before('Rack::Sendfile', 'Rack::Static', options)
    Sass::Plugin.options[:never_update] = true
  end
end
