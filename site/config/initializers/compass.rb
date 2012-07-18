#
# All production environments pregenerate CSS using the RPM build, development
# environments use autogeneration.  To trigger autogeneration you may need to
# run 'rake assets:clean'.
#
if Rails.env.development?
  options = {
    :urls => ['/stylesheets'],
    :root => "#{Rails.root}/tmp"
  }

  Rails.configuration.middleware.insert_after('Sass::Plugin::Rack', 'Rack::Static', options)

  Sass::Plugin.options[:style] = :expanded
  Sass::Plugin.options[:line_numbers] = true
  Sass::Plugin.options[:debug_info] = true
else
  Sass::Plugin.options[:never_update] = true
end
