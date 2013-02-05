# This configuration file works with both the Compass command line tool and within Rails.
#require 'html5-boilerplate'
# Require any additional compass plugins here.

project_type = :rails

# Set this to the root of your project when deployed:
http_path = "/console"

#if Compass::AppIntegration::Rails.env == 'development'
css_dir = "tmp/stylesheets"
#end

# You can select your preferred output style here (can be overridden via the command line):
output_style = (environment == :production) ? :compressed : :nested #:expanded or :nested or :compact or :compressed

# To enable relative paths to assets via compass helper functions. Uncomment:
relative_assets = true

# To disable debugging comments that display the original location of your selectors. Uncomment:
line_comments = (environment != :production)

sass_options = (environment != :production) ? {debug_info: true} : {}

# If you prefer the indented syntax, you might want to regenerate this
# project again passing --syntax sass, or you can uncomment this:
# preferred_syntax = :sass
# and then run:
# sass-convert -R --from scss --to sass app/stylesheets scss && rm -rf sass && mv scss sass
