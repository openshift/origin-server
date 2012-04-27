#
# Stylesheets are assumed to be generated into Rails tmp/stylesheets,
# either dynamically in development, or by the RPM build in production
#
options = {
  :urls => ['/stylesheets'],
  :root => "#{Rails.root}/tmp"
}

#
# All production environments pregenerate CSS using the RPM build, development
# environments use autogeneration
#
if Rails.env.development?
  Rails.configuration.middleware.insert_after('Sass::Plugin::Rack', 'Rack::Static', options)
  Sass::Plugin.options[:style] = :expanded
  Sass::Plugin.options[:line_numbers] = true
  Sass::Plugin.options[:debug_info] = true
else
  Rails.configuration.middleware.insert_before('Rack::Sendfile', 'Rack::Static', options)
  Sass::Plugin.options[:never_update] = true
end
