unless true #Console.config.disable_css
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
  # environments use autogeneration.  To trigger autogeneration you may need to
  # run 'rake assets:clean'.
  #
  if Rails.env.development?
    Rails.configuration.middleware.insert_after('Sass::Plugin::Rack', 'Rack::Static', options)

    Sass::Plugin.options[:style] = :expanded
    Sass::Plugin.options[:line_numbers] = true
    Sass::Plugin.options[:debug_info] = true
  else
    Sass::Plugin.options[:never_update] = true
  end
end
